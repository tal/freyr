module Freyr
  class Service
    extend Forwardable
    class << self
      def add_service_method *methods
        
      end
    end
    
    attr_reader :info, :command, :defined_in_paths

    def_delegators :info, :name, :groups
    
    def initialize(s)
      @info = s
      @command = Command.new(self)
      Service.by_selector[name] = ServiceGroup.new(self)
      Service.s[name] = self
      Service.by_name[name] = self
    end
    class NoProcMatch < StandardError; end

    def pid_file
      @pid_file ||= begin
        raise NoProcMatch, "please provide proc_match for service #{@info.name}" unless @info.proc_match
        PidFile.new(@info.pid_file,@info.proc_match)
      end
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
      pid_file.alive?
    end

    def call_graph
      graph = Hash.new {|h,k| h[k]=[]}
      graph[self]
      @info.dependencies.each do |dep|
        if d = Service.s[dep]
          graph[self] << d
          graph.merge!(d.call_graph)
        end
      end
      graph
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
      log_location = @info.log
      if File.exist?(log_location)
        cmd = "tail -#{size}#{f} #{log_location}"
        Freyr.logger.debug("tailing cmd") {cmd.inspect}
        exec(cmd)
      else
        error("no logfile found at #{log_location}")
        abort("no logfile found at #{log_location}")
      end
    end
    
    def error *args, &blk
      Freyr.logger.error(*args,&blk)
      Freyr.logger.debug("service info for service with error #{self}") {@info.inspect}
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
        ServiceInfo.from_file(f)

        @all_services
      end
      
      def [](name)
        by_selector.has_key?(name) ? by_selector[name] : nil
      end
      
    end
    
  end
  
end