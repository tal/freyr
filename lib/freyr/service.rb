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
    
    add_service_method :start, :start_command
    
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
      return unless start_command
      command.run! unless alive?
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
    
    def tail!(size = 600, follow = true)
      f = follow ? 'f' : ''
      Dir.chdir dir
      exec("tail -#{size}#{f} #{log}")
    end
    
    def describe
      %Q{#{name}(#{groups.join(',')}) - #{start_command}}
    end
    
    def matches?(n)
      n = n.to_s
      return true if name.to_s == n
      
      also.find {|a| a.to_s == n}
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
        
        services = ServiceInfo.from_file(f).collect do |ser|
          raise 'Cannot have two things of the same name' if selectors.include?(ser.name)
          names |= [ser.name]
          @all_groups |= ser.groups
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