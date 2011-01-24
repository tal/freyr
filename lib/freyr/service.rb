module Freyr
  class Service
    extend Forwardable
    
    attr_reader :service_info, :command
    
    def initialize(s)
      @service_info = s
      @command = Command.new(self)
    end
    
    def_delegators :@service_info, *ServiceInfo::ATTRS
    def_delegator  :@service_info, :start, :start_command
    
    def env
      service_info.env || {}
    end
    
    def log
      @service_info.log || File.join(command.file_dir,"#{name}.log")
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
          names << ser.name
          @all_groups |= ser.groups
          new(ser)
        end
        
        @all_services += services
      end
      
      def [](name)
        if ser = s.find {|sr| sr.matches?(name)}
          [ser]
        else
          s.select {|sr| sr.is_group?(name)}
        end
      end
      
    end
    
  end
  
end