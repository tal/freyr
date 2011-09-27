module Freyr
  
  class Command
    extend Forwardable
    
    attr_reader :name, :service
    
    def initialize(service, command=nil, args = {})
      @service = service
    end

    def_delegators :'@service', :info
    def_delegators :info, :name, :env

    def command
      info.start
    end
    
    def run!
      return unless command
      kill! if service.alive?
      
      require_admin
      
      total_time = Time.now
      
      pid = spawn(command)
      
      Freyr.logger.debug("attempting to run command") {command.inspect}
      str = "\nStarting #{info.name} with #{command.inspect}"
      OUT.puts '',"Starting #{info.name} with #{command.inspect}", '='*str.length
      Process.detach(pid)
      
      pid = service.pid_file.wait_for_pid
      
      OUT.puts "PID of new #{info.name} process is #{pid}"
      
      if info.ping
        pinger = Pinger.new(@service)
        
        pinger.wait_for_resp { @service.alive? }
      end
      
      if @service.alive?
        OUT.puts "Launch took about #{(Time.now-total_time).ceil} seconds"
        pid
      else
        OUT.puts "#{info.name} service wasn't launched correctly. For details see: #{info.log}"
      end
    end
    
    def kill!(sig=nil)
      require_admin
      sig ||= info.stop_sig || 'KILL'
      
      Freyr.logger.debug("sending signal to process") {"Signal: #{sig}, PID: #{pid}"}
      
      if pid(true)
        Process.kill(sig, pid)
      end
    end

    def pid force = false
      @service.pid_file.pid(force)
    end
    
    def restart!
      require_admin
      
      if info.restart
        chdir
        system(info.restart)
      elsif info.restart_sig
        kill!(info.restart_sig)
      else
        run!
      end
    end
    
    private
    
    def require_admin
      raise AdminRequired if info.sudo && !Freyr.is_root?
    end
    
    def chdir
      Dir.chdir File.expand_path(info.dir||'/')
    end
    
    def spawn(command)
      if info.rvm && RVM.installed?
        Freyr.logger.debug('attempting to set rvm') {info.rvm}
        if RVM.installed?(info.rvm)
          command = "rvm #{info.rvm} exec #{command}"
          Freyr.logger.debug('changed command to') {command}
        else
          abort("must setup rvm correctly, run: rvm --install --create #{info.rvm}")
        end
      elsif info.rvm
        Freyr.logger.debug("rvm not installed so can't switch to") {info.rvm}
      end

      fork do
        File.umask info.umask if info.umask
        uid_num = Etc.getpwnam(info.uid).uid if info.uid
        gid_num = Etc.getgrnam(info.gid).gid if info.gid
        
        ::Dir.chroot(info.chroot) if info.chroot
        ::Process.setsid
        ::Process.groups = [info.guid] if info.gid
        ::Process::Sys.setgid(info.guid) if info.gid
        ::Process::Sys.setuid(info.guid) if info.uid
        chdir
        $0 = "freyr - #{name} (#{command})"
        STDIN.reopen "/dev/null"
        if info.log_cmd
          STDOUT.reopen IO.popen(log_cmd, "a")
        elsif info.log && !info.dont_write_log
          STDOUT.reopen info.log, "a"
        else
          STDOUT.reopen "/dev/null"
        end
        if info.err_log_cmd
          STDERR.reopen IO.popen(info.err_log_cmd, "a") 
        elsif info.err_log && (info.log_cmd || info.err_log != info.log)
          STDERR.reopen info.err_log, "a"
        else
          STDERR.reopen STDOUT
        end
        
        # close any other file descriptors --- I think this is for anything after stderr
        3.upto(256){|fd| IO::new(fd).close rescue nil}
        
        if @env && @env.is_a?(Hash)
          @env.each do |(key, value)|
            ENV[key] = value
          end
        end
        
        exec(command)
      end
    end
    

    class << self
      def add_service_method *methods
      end
    end
  end
  
  class AdminRequired < Errno::EACCES; end
  
end
