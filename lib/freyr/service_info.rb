module Freyr
  class ServiceInfo
    attr_reader :groups
    
    class << self
      def add_service_method *methods
        Service.send :add_service_method, *methods
        Command.send :add_service_method, *methods
        methods.each do |method|
          ATTRS << methods
        end
      end
    end
    
    ATTRS = []
    add_service_method :name,:dir,:log_cmd,:log,:err_log_cmd,:err_log,:umask,
                        :uid,:gid,:chroot,:proc_match,:restart,:stop,:stop_sig,
                        :restart_sig,:sudo,:groups,:ping,:also,:dependencies,:read_log
    
    def initialize(name=nil, args={}, &block)
      @groups = []
      @also = []
      @dependencies = []
      if name.is_a?(Hash)
        @name = name.keys.first
        @groups << name[@name]
      else
        @name = name
      end
      
      instance_eval(&block)
    end
    
    def use_sudo
      @sudo = true
    end
    
    def group(*val)
      @groups |= val
    end
    
    def requires *val
      @dependencies |= val
    end
    
    def also_as(*val)
      @also |= val
    end
    
    MODIFIERS = Hash.new {|h,k| h[k] = []}
    MODIFIERS[:start] << :_sudo_checker
    MODIFIERS[:stop] << :_sudo_checker
    MODIFIERS[:restart] << :_sudo_checker
    
    def method_missing key, val=nil
      key = key.to_s.gsub(/\=$/,'').to_sym
      
      if val
        MODIFIERS[key].each do |modifier|
          val = send(modifier,val)
        end
        instance_variable_set("@#{key}", val)
      else
        instance_variable_get("@#{key}")
      end
    end
    
    SUDO_MATCHER = /^sudo\s+/
    
  private
    
    # If someone doesn't explicitly not want the script running as admin
    # and the val looks like it's supposed to be run in sudo remove sudo
    # and force to be run as admin
    def _sudo_checker(val)
      if @admin != false && val =~ SUDO_MATCHER
        val.gsub!(SUDO_MATCHER,'')
        use_sudo
      end
      val.chomp
    end
    
    class << self
      
      def from_file file
        file = File.expand_path(file)
        return [] unless File.exist?(file)
        @added_services = []
        instance_eval(File.open(file).read)
        @added_services
      end
      
      def method_missing *args
        
      end
      
    private
      
      def namespace name
        @namespace = name
      end
      
      def group name, *services
        puts "Trying #{name.inspect} on #{services.inspect}"
        services.each do |s|
          Service[s].each do |service|
            puts "Service: #{service.name}"
            service.service_info.group(name)
          end
        end
      end
      
      def service name=nil, &blk
        name = "#{@namespace}:#{name}" if @namespace
        if service = Service[name].first
          service.service_info.instance_eval(&blk)
        else
          @added_services << new(name,&blk)
        end
      end
    end
    
  end
end