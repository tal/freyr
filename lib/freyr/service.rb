module Freyr
  class Service
    extend Forwardable
    
    attr_reader :service_info, :command
    
    def initialize(s)
      @service_info = s
      @command = Command.new(self)
    end
    
    def_delegators :@service_info, :name, :dir, :log_cmd, :log, :err_log_cmd, :err_log, :groups, :proc_match, :restart_cmd
    def_delegator  :@service_info, :start, :start_command
    
    def env
      service_info.env || {}
    end
    
    def log
      (@service_info && @service_info.log) || File.join(Command::FREYR_PIDS,"#{name}.log")
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
      groups.find {|g| g.to_s == name.to_s}
    end
    
    def alive?
      command.alive?
    end
    
    def tail!(size = 600, follow = true)
      f = follow ? 'f' : ''
      exec("tail -#{size}#{f} #{log}")
    end
    
    def describe
      %Q{#{name}(#{groups.join(',')}) - #{start_command}}
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
        if ser = s.find {|sr| sr.name.to_s == name.to_s}
          [ser]
        else
          s.select {|sr| sr.is_group?(name)}
        end
      end
      
    end
    
  end
  
  class ServiceInfo
    attr_reader :groups
    
    def initialize(name=nil, args={}, &block)
      @groups = []
      if name.is_a?(Hash)
        @name = name.keys.first
        @groups << name[@name]
      else
        @name = name
      end
      
      instance_eval(&block)
    end
    
    def group(*val)
      @groups |= val
    end
    
    def method_missing *args
      key, val = *args
      
      key = key.to_s.gsub(/\=$/,'')
      if val
        instance_variable_set("@#{key}", val)
      else
        instance_variable_get("@#{key}")
      end
    end
    
    class << self
      
      def from_file file
        file = File.expand_path(file)
        return [] unless File.exist?(file)
        @added_services = []
        instance_eval(File.open(file).read)
        @added_services
      end
      
    private
      
      def namespace name
        @namespace = name
      end
      
      def service name=nil, &blk
        name = "#{@namespace}:#{name}" if @namespace
        @added_services << new(name,&blk)
      end
    end
    
  end
  
end