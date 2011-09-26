module Freyr
  class Service
    extend Forwardable
    class << self
      def add_service_method *methods
        
      end
    end
    
    attr_reader :info, :command, :pid_file, :defined_in_paths

    def_delegators :info, :name, :groups
    
    def initialize(s)
      @info = s
      @command = Command.new(self)
      raise Exception, "please provide proc_match for service #{@info.name}" unless @info.name
      @pid_file = PidFile.new(s.pid_file,s.proc_match)
      @defined_in_paths = []
    end
    
    def start!
      command.run! unless alive?
    end
    
    def stop!
      command.kill!
    end
    
    def restart!
      command.restart!
    end
    
    def is_group?(name)
      @info.groups.find {|g| g.to_s == name.to_s}
    end
    
    def alive?
      @pid_file.alive?
    end

    def dependencies(yell = false)
      missing = []
      deps = @info.dependencies.inject([]) do |all,dep|
        if d = Service.s[dep]
          all | (d.dependencies(yell) + [d])
        else
          missing << dep
          all
        end
      end

      if yell && !missing.empty?
        raise MissingDependency, "missing #{missing.join(', ')} dependencies"
      end

      deps.compact
    end
    
    def ping!
      if @info.ping
        pinger = Pinger.new(self)
        pinger.ping
        pinger
      end
    end
    
    def tail!(size = 600, follow = true)
      f = follow ? 'f' : ''
      if @info.read_log
        cmd = "tail -#{size}#{f} #{File.join(@info.dir||'/',@info.log)}"
        Freyr.logger.debug("tailing cmd") {cmd.inspect}
        exec(cmd)
      else
        error("no logfile found")
        exit(false)
      end
    end
    
    def error *args, &blk
      Freyr.logger.error(*args,&blk)
      Freyr.logger.debug("service info for service #{self}") {@info.inspect}
    end
    
    def describe
      %Q{#{@info.name}(#{@info.groups.join(',')}) - #{@info.start}}
    end
    
    def matches?(n)
      n = n.to_s
      return true if @info.name.to_s == n
      
      @info.also.find {|a| a.to_s == n}
    end
    
    def inspect
      %Q{#<Freyr::Service #{@info.name} #{@info.start.inspect}>}
    end

    class MissingDependency < StandardError; end
    
    class << self
      # Get by name only
      def s
        @all_services ||= {}
      end
      
      def selectors
        by_selector.keys
      end

      def by_dir
        @by_dir ||= {}
      end

      # Get by name and alias
      def by_name
        @by_name ||= {}
      end

      # by group/alias/name and always a servicegroup
      def by_selector
        @by_selector ||= Hash.new {|h,k| h[k] = ServiceGroup.new}
      end
      
      def add_file f
        Freyr.logger.debug('adding file') {f}
        
        ServiceInfo.from_file(f).each do |ser|
          if self[ser.name]
            Freyr.logger.error('name already taken') {"Cannot add service #{ser.name} because the name is already used"}
            next
          end
          service = new(ser)
          service.defined_in_paths << File.expand_path(f)
          self.by_selector[ser.name] = ServiceGroup.new service
          self.s[ser.name] = service
          self.by_name[ser.name] = service
          self.by_dir[ser.dir] = service
          ser.groups.each {|group| self.by_selector[group] << service }
          ser.also.each do |also_as|
            self.by_selector[also_as] = self.by_selector[ser.name]
            self.by_name[also_as] = self.by_name[ser.name]
          end
        end

        @all_services
      end
      
      def [](name)
        by_selector.has_key?(name) ? by_selector[name] : nil
      end
      
    end
    
  end
  
end