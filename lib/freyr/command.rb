module Freyr
  
  class Command
    extend Forwardable
    
    ROOT_PIDS = '/var/run/freyr'
    FREYR_PIDS = ENV['USER'] == 'root' ? ROOT_PIDS : File.expand_path('.freyr', '~')
    
    if !File.exist?(FREYR_PIDS)
      Dir.mkdir(FREYR_PIDS)
    elsif !File.directory?(FREYR_PIDS)
      File.delete(FREYR_PIDS)
      Dir.mkdir(FREYR_PIDS)
    end
    
    ServiceInfo::ATTRS.each do |meth|
      define_method(meth) do |*args|
        @service.__send__(meth,*args) if @service
      end
    end
    
    attr_reader :command, :name, :service
    
    def initialize(name, command=nil, args = {})
      if name.is_a?(Service)
        @service = name
        @name = service.name
        @command = service.start_command
        @env = service.env
      else
        @name = name
        @command = command
        
        @env = args[:env]
      end
    end
    
    def pid_file
      File.join(file_dir,"#{@name}.pid")
    end
    
    def file_dir
      admin? ? ROOT_PIDS : FREYR_PIDS
    end
    
    def read_pid
      return unless File.exist?(pid_file)
      p = File.open(pid_file).read
      p ? p.to_i : nil
    end
    
    def pid(force = false)
      @pid = nil if force
      @pid ||= read_pid
    end
    
    def alive?
      return unless pid
      Process.getpgid(pid)
      true
    rescue Errno::ESRCH
      retried = false unless defined?(retried)
      
      if !retried && @pid = pid_from_procname
        save
        retried = true
        retry
      end
      
      if pid(true)
        File.delete(pid_file) unless admin? && !is_root?
      end
      
      false
    end
    
    def delete_if_dead
      !alive?
    end
    
    def save
      if File.exist?(pid_file)
        old_pid = read_pid
        begin
          Process.kill('KILL', old_pid) if old_pid && old_pid.to_s != @pid.to_s
        rescue Errno::ESRCH
        end
      end
      
      File.open(pid_file, 'w') {|f| f.write(@pid)}
    end
    
    def run!
      return unless command
      kill! if alive?
      
      require_admin
      
      total_time = Time.now
      
      pid = spawn(command)
        
      @pid = pid
        
      Process.detach(@pid)
      
      if proc_match
        puts "Waiting for pid from match of #{proc_match.inspect}"
        
        start = Time.now
        until (pid = pid_from_procname) || (Time.now-start) > 40
          print '.'; STDOUT.flush
          sleep(0.2)
        end
        
        raise "\nCouldnt find pid after 40 seconds" unless pid
        
        puts '*'
        
        @pid = pid
      end
      
      puts "PID of new #{name} process is #{@pid}"
      save
      
      if ping
        pinger = Pinger.new(self)
        
        puts '',"Waiting for response from #{pinger.url}"
        
        # Move this pinger code somewhere else
        start = Time.now
        begin
          print '.'; STDOUT.flush
          pinger.ping
          sleep(0.6)
        end until pinger.server_probably_launched? || (Time.now-start) > 40 || !alive?
        
        if alive?
          
          if pinger.response
            puts '*',"Last response recieved with code #{pinger.response.code}"
          else
            puts 'x',"Couldn't reach #{name} service"
          end
        else
          puts 'x', "Service died durring launch"
        end
      end
      
      if alive?
        puts "Launch took about #{(Time.now-total_time).ceil} seconds"
        
        @pid
      else
        puts "#{name} service wasn't launched correctly. For details see: #{log}"
        delete_if_dead
      end
    end
    
    def update_pid
      if @pid = pid_from_procname
        save
        @pid
      end
    end
    
    def pid_from_procname
      return unless proc_match
      
      pids = `ps -eo pid,command`.split("\n").inject({}) do |r, pid|
        if m = pid.match(/^\s*(\d+)\s(.+)$/)
          r[m[2]] = m[1].to_i
        end
        r
      end
      
      if procline = pids.keys.find {|p| p.match(proc_match)}
        pids[procline]
      end
    end
    
    def kill!(sig=nil)
      require_admin
      sig ||= stop_sig || 'KILL'
      
      if pid(true)
        Process.kill(sig, pid)
      end
    end
    
    def restart!
      require_admin
      
      if restart
        chdir
        system(restart)
        update_pid
      elsif restart_sig
        kill!(restart_sig)
      else
        run!
      end
    end
    
    def admin?
      sudo
    end
    
    private
    
    def require_admin
      raise AdminRequired if admin? && !is_root?
    end
    
    def is_root?
      ENV['USER'] == 'root'
    end
    
    def chdir
      Dir.chdir File.expand_path(dir||'/')
    end
    
    def spawn(command)
      fork do
        # File.umask self.umask if self.umask
        # uid_num = Etc.getpwnam(self.uid).uid if uid
        # gid_num = Etc.getgrnam(self.gid).gid if gid
        
        # ::Dir.chroot(self.chroot) if self.chroot
        ::Process.setsid
        # ::Process.groups = [gid_num] if self.gid
        # ::Process::Sys.setgid(gid_num) if self.gid
        # ::Process::Sys.setuid(uid_num) if self.uid
        chdir
        $0 = "freyr - #{name} (#{command})"
        STDIN.reopen "/dev/null"
        if log_cmd
          STDOUT.reopen IO.popen(log_cmd, "a")
        elsif log
          STDOUT.reopen log, "a"
        end
        if err_log_cmd
          STDERR.reopen IO.popen(err_log_cmd, "a") 
        elsif err_log && (log_cmd || err_log != log)
          STDERR.reopen err_log, "a"
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
        
        exec(command) unless command.empty?
      end
    end
    
  end
  
  class AdminRequired < Errno::EACCES; end
  
end
