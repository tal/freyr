module Freyr
  class CLI < Thor
    # TODO: DRY up start/restart/stop commands
    
    desc 'start [SERVICE=dirname]', 'Start particular service'
    def start(name=nil)
      services = get_from_name(name)
      if !services.empty?
        Freyr.logger.debug('starting services') {services.inspect}
        names = services.call_order.collect {|s| s.name}
        say "Starting the " << set_color(names.join(', '), :blue) << ' services'
        
        changed_names = services.run
        
        list_all_services(:highlight_state => changed_names).each {|l| say(l)}
      else
        say "Can't find the #{name} service", :red
        exit(false)
      end
    rescue AdminRequired
      say "Please run in sudo to launch #{name}.", :red
      exit(false)
    rescue Service::MissingDependency => e
      say "Missing dependency, could not launch service: #{e.to_s}"
      exit(false)
    end
    
    desc 'stop [SERVICE=dirname]', 'Stop particular service'
    def stop(name=nil)
      services = get_from_name(name)
      if !services.empty?
        Freyr.logger.debug('stopping services') {services.inspect}
        names = services.collect {|s| s.name}
        say "Stopping the " << set_color(names.join(', '), :blue) << ' services'
        
        changed_names = services.stop
        
        list_all_services(:highlight_state => changed_names).each {|l| say(l)}
      else
        say "Can't find the #{name} service", :red
        exit(false)
      end  
    rescue AdminRequired
      say "Please run in sudo to stop #{name}.", :red
      exit(false)
    end
    
    desc 'restart [SERVICE=dirname]', 'restart particular service'
    def restart(name=nil)
      services = get_from_name(name)
      if !services.empty?
        Freyr.logger.debug('restarting services') {services.inspect}
        say "Restarting the " << set_color(services.collect {|s| s.name}.join(', '), :blue) << ' services'
        
        names = services.restart
        
        list_all_services(:highlight_state => names).each {|l| say(l)}
      else
        say "Can't find the #{name} service", :red
        exit(false)
      end
      
    rescue AdminRequired
      say "Please run in sudo to launch #{name}.", :red
      exit(false)
    end
    
  end
end
