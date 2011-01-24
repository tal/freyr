module Freyr
  class CLI < Thor
    # TODO: DRY up start/restart/stop commands
    
    desc 'start [SERVICE=dirname]', 'Start particular service'
    def start(name=nil)
      services = get_from_name(name)
      if !services.empty?
        names = services.collect {|s| s.name}
        say "Starting the " << set_color(names.join(', '), :blue) << ' services'
        
        changed_names = services.collect do |s|
          begin
            pid = s.start!
            s.name if pid
          rescue AdminRequired
            say "Please run in sudo to launch #{s.name}.", :red
            nil
          end
        end.compact
        
        list_all_services(:highlight_state => changed_names).each {|l| say(l)}
      else
        say "Can't find the #{name} service", :red
      end
    end
    
    desc 'stop [SERVICE=dirname]', 'Stop particular service'
    def stop(name=nil)
      services = get_from_name(name)
      if !services.empty?
        names = services.collect {|s| s.name}
        say "Stopping the " << set_color(names.join(', '), :blue) << ' services'
        changed_names = services.collect {|s| s.name if s.alive?}.compact
        
        services.each do |s|
          begin
            s.stop!
          rescue AdminRequired
            say "Please run in sudo to stop #{s.name}.", :red
          end
        end
        
        list_all_services(:highlight_state => changed_names).each {|l| say(l)}
      else
        say "Can't find the #{name} service", :red
      end
    end
    
    desc 'restart [SERVICE=dirname]', 'restart particular service'
    def restart(name=nil)
      services = get_from_name(name)
      if !services.empty?
        names = services.collect {|s| s.name}
        say "Restarting the " << set_color(names.join(', '), :blue) << ' services'
        
        services.each do |s|
          begin
            s.restart!
          rescue AdminRequired
            say "Please run in sudo to launch #{s.name}.", :red
            name.delete(s.name)
            nil
          end
        end
        
        list_all_services(:highlight_state => names).each {|l| say(l)}
      else
        say "Can't find the #{name} service", :red
      end
    end
    
  end
end