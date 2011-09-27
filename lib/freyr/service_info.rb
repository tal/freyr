module Freyr
  class ServiceInfo
    attr_reader :groups
    ROOT_PIDS = '/var/run/freyr'.freeze
    USER_PIDS = File.expand_path('.freyr', '~').freeze
    ROOT_LOGS = '/var/log/freyr'.freeze
    USER_LOGS = USER_PIDS
    failed = []
    [ROOT_PIDS,USER_PIDS,ROOT_LOGS,USER_LOGS].each do |dir|
      begin
        FileUtils.mkdir_p(dir)
      rescue Errno::EACCES => e
        failed << dir
      end
    end

    module Base

      module ClassMethods

        def add_service_method *methods
          Service.send :add_service_method, *methods
          Command.send :add_service_method, *methods
          methods.each do |method|
            InstanceMethods.instance_eval do
              define_method method do |*args|
                val = args
                val = val.first if val.size < 2
                if val
                  MODIFIERS[method].each do |mod|
                    val = send(mod,val)
                  end
                  instance_variable_set("@#{method}",val)
                else
                  instance_variable_get("@#{method}")
                end
              end
              
            end

          end
        end

      end
      
      module InstanceMethods
        
      end
      
      def self.included(receiver)
        receiver.extend         ClassMethods
        receiver.send :include, InstanceMethods
      end
    end
    include Base
    
    
    MODIFIERS = Hash.new {|h,k| h[k] = []}
    MODIFIERS[:start] << :_sudo_checker
    MODIFIERS[:stop] << :_sudo_checker
    MODIFIERS[:restart] << :_sudo_checker
    ATTRS = []
    add_service_method  :start,:name,:dir,:log_cmd,:log,:err_log_cmd,:err_log,:umask,
                        :uid,:gid,:chroot,:proc_match,:restart,:stop,:stop_sig,
                        :restart_sig,:sudo,:groups,:ping,:also,:dependencies,:read_log,
                        :pid_file, :dont_write_log,:env, :rvm
    alias log_file log
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
      
      instance_eval(&block) if block_given?
    end
    
    def use_sudo
      @sudo = true
    end

    def env val=nil
      raise TypeError, 'environment must be a hash' unless val.is_a?(Hash) || val.nil?
      if val = super
        val
      else
        {}
      end
    end
    
    def pid_file val=nil
      if val = super
        val
      else
        if @sudo
          File.join(ROOT_PIDS,"#{@name}.pid")
        else
          File.join(USER_PIDS,"#{@name}.pid")
        end
      end
    end

    def read_log val=nil
      @dont_write_log = true
      super
    end

    def log val=nil
      val = if val = super
        val
      else
        if @read_log
          @read_log
        else
          if @sudo
            File.join(ROOT_LOGS,"#{@name}.log")
          else
            File.join(USER_LOGS,"#{@name}.log")
          end
        end
      end

      val =~ /^\// ? val : File.join(dir,val)
    end

    def dir val=nil
      if val = super
        val
      else
        '/'
      end
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
        @file_path = file
        file = File.expand_path(file)
        Freyr.logger.debug("adding file")  {file}
        return [] unless File.exist?(file)
        @added_services = []
        instance_eval(File.open(file).read,file,0)
        @added_services
      end
      
      def method_missing name, *args, &blk
        STDERR.puts "Freyr doesn't support #{name} as used in #{@file_path}"
      end
      
    private
      
      def namespace name
        @namespace = name
      end
      
      def group name, *services
        services.each do |s|
          services = Service[s]
          if services
            services.each do |service|
              service.service_info.group(name)
            end
          else
            STDERR.puts "Service #{s} not found, can't add to group #{name} as attempted in #{@file_path}"
          end
        end
      end
      
      def service name=nil, &blk
        name = "#{@namespace}:#{name}" if @namespace
        if service = Service[name]
          service.info.instance_eval(&blk)
        else
          @added_services << new(name,&blk)
        end
      end
    end
    
  end
end