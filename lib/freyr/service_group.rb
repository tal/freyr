module Freyr
  class ServiceGroup < DelegateClass(Array)
    extend Forwardable
    service_methods = Service.instance_methods - Class.instance_methods
    def_delegators :first, *service_methods
    
    def initialize *services
      @all_services = []
      super(services)
    end

    def find_by_name(n)
      find {|s| s.name == n}
    end

    def update_services
      dependencies = inject([]) do |deps,svc|
        deps | svc.dependencies(true)
      end
      @all_services = dependencies|@_dc_obj
    end

    def inspect
      %Q{#<#{self.class.inspect} #{@_dc_obj.collect{|s| s.name}.join(', ')}>}
    end
    
    def run
      return [] if empty?

      services = update_services

      services.collect do |service|
        service.name if service.start!
      end
    end
    
    def stop
      changed_names = collect {|s| s.name if s.alive?}.compact
      each do |svc|
        Freyr.logger.debug('stopping service') {svc.name}
        svc.stop!
      end
      
      changed_names
    end
    
    def restart
      names = collect {|s| s.name}
      
      each do |s|
        Freyr.logger.debug('restart service') {s.name}
        s.restart!
        names.delete(s.name)
      end
      
      names
    end

  end
end
