module Freyr
  class Service
    extend Forwardable
    class << self
      def add_service_method *methods
        def_delegators :@service_info, *methods
      end
    end
    
    attr_reader :service_info, :command
    
    def initialize(s)
      @service_info = s
      @command = Command.new(self)
    end
    
    def start_command
      @service_info.start
    end
    
    def env
      service_info.env || {}
    end
    
    def log
      @service_info.read_log || @service_info.log || File.join(command.file_dir,"#{name}.log")
    end
    
    def write_log?
      @service_info.log && !@service_info.read_log
    end
    
    def start!
      if start_command
        command.run! unless alive?
      else
        error("no start_command")
      end
    end
    
    def stop!
      command.kill! if start_command
    end
    
    def restart!
      command.restart!
    end
    
    def is_group?(name)
      groups.find {|g| g.to_s == name.to_s}
    end
    
    def alive?
      command.alive?
    end
    
    def ping!
      if ping
        pinger = Pinger.new(self)
        pinger.ping
        pinger
      end
    end
    
    def read_log
      @service_info.log || @service_info.read_log
    end
    
    def tail!(size = 600, follow = true)
      f = follow ? 'f' : ''
      if read_log
        cmd = "tail -#{size}#{f} #{File.join(dir||'/',read_log)}"
        Freyr.logger.debug("tailing cmd") {cmd.inspect}
        exec(cmd)
      else
        error("no logfile found")
      end
    end
    
    def error *args, &blk
      Freyr.logger.error(*args,&blk)
      Freyr.logger.debug("service info for service #{self}") {@service_info.inspect}
    end
    
    def describe
      %Q{#{name}(#{groups.join(',')}) - #{start_command}}
    end
    
    def matches?(n)
      n = n.to_s
      return true if name.to_s == n
      
      also.find {|a| a.to_s == n}
    end
    
    def inspect
      %Q{#<Freyr::Service #{name} #{start_command.inspect}>}
    end
    
    class << self
      
      def s
        @all_services ||= []
      end
      
      def names
        @all_names ||= []
      end
      
      def groups
        @all_groups ||= []
      end
      
      def selectors
        names+groups
      end
      
      def add_file f
        s
        
        Freyr.logger.debug('adding file') {f}
        
        services = ServiceInfo.from_file(f).collect do |ser|
          raise 'Cannot have two things of the same name' if selectors.include?(ser.name)
          names |= [ser.name]
          @all_groups |= ser.groups
          Freyr.logger.debug('adding service') {ser.name.inspect}
          new(ser)
        end
        
        @all_services += services
      end
      
      def alive?(name)
        !!self[name].find do |ser|
          ser.alive?
        end
      end
      
      def [](name)
        group = ServiceGroup.new
        
        if ser = s.find {|sr| sr.matches?(name)}
          group << ser
        else
          s.each do |sr|
            if sr.is_group?(name)
              group << sr
            end
          end
        end
        
        group
      end
      
    end
    
  end
  
end