require 'thor'

module Freyr
  class CLI < Thor
    include Thor::Actions
    
    def initialize(*)
      super
      get_services
    end
    
    class_option :'config-file', :desc => 'config file to use', :type => :string
    
    desc 'update_pid', 'Update pid from proc_match (good to use if service already launched)'
    def update_pid(name)
      services = Service[name]
      if s = services.first
        if pid = s.command.update_pid
          say "Updated pid for "<< set_color(s.name,:blue) << ' to ' << set_color(pid,:red)
        elsif s.proc_match
          say "Couldn't find pid for process matcher #{s.proc_match.inspect}", :red
        else
          say "Service #{s.name} doesn't have a value for proc_match set.", :red
        end
      else
        say "Couldn't find service with name #{name}.", :red
      end
    end
    
    desc 'start', 'Start particular service'
    def start(name)
      services = Service[name]
      if !services.empty?
        names = services.collect {|s| s.name}
        say "Starting the " << set_color(names.join(', '), :blue) << ' services'
        
        changed_names = services.collect do |s|
          pid = s.start!
          s.name if pid
        end.compact
        
        list_all_services(:highlight_state => changed_names).each {|l| say(l)}
      else
        say "Can't find the #{name} service", :red
      end
    end
    
    desc 'stop', 'Stop particular service'
    def stop(name)
      services = Service[name]
      if !services.empty?
        names = services.collect {|s| s.name}
        say "Stopping the " << set_color(names.join(', '), :blue) << ' services'
        changed_names = services.collect {|s| s.name if s.alive?}.compact
        
        services.each {|s| s.stop!}
        
        list_all_services(:highlight_state => changed_names).each {|l| say(l)}
      else
        say "Can't find the #{name} service", :red
      end
    end
    
    desc 'restart', 'restart particular service'
    def restart(name)
      services = Service[name]
      if !services.empty?
        names = services.collect {|s| s.name}
        say "Restarting the " << set_color(names.join(', '), :blue) << ' services'
        
        services.each {|s| s.restart!}
        
        list_all_services(:highlight_state => names).each {|l| say(l)}
      else
        say "Can't find the #{name} service", :red
      end
    end
    
    desc 'tail', 'read stdout of the service'
    method_option :lines, :type => :numeric, :default => 50, :desc => 'Number of lines to show on initial tail'
    method_option :'no-follow', :type => :boolean, :default => false, :desc => 'Disable auto follow, just print tail and exit'
    def tail(name)
      services = Service[name]
      if !services.empty?
        
        services.first.tail!(options.lines, !options['no-follow'])
      else
        say "Can't find the #{name} service", :red
      end
    end
    
    desc 'list', 'lists all available services:'
    def list
      strs = list_all_services
      
      if strs.empty?
        say "No services available", :red
      else
        say "List of all available services"
        strs.each_with_index do |s,i|
          say s
        end
      end
    end
    
  private
    
    # Ugh, this is ugly, colorizing stuff is rough
    def list_all_services(args={})
      args[:highlight_name] = (args[:highlight_name]||[]).collect {|n| n.to_s}
      args[:highlight_state] = (args[:highlight_state]||[]).collect {|n| n.to_s}
      
      max_length = 0
      lengths = Service.s.collect do |s|
        n = "   #{s.name}(#{s.groups.join(', ')})"
        max_length = n.length if n.length > max_length
        n.length
      end
      
      max_length += 3 # min distance between name and group
      
      strs = []
      Service.s.each_with_index do |s,i|
        str = '   '
        name = set_color(s.name, :blue)
        if args[:highlight_name].include?(s.name.to_s)
          name = set_color(name, :on_white)
        end
        str << name
        str << " "*(max_length - lengths[i])
        if s.groups.empty?
          str << '  '
        else
          str <<  '('
          s.groups.each do |g|
            str << set_color(g,:red)
            next if g == s.groups.last
            str << ', '
          end
          str << ')'
        end
        
        str << ' - '
        if s.alive?
          state = set_color(' Alive ', :green, false)
        else
          state = set_color(' Dead ', :red, true)
        end
        
        if args[:highlight_state].include?(s.name.to_s)
          state = set_color(state, :on_white)
        end
        
        str << state
        
        strs << str
      end
      
      strs
    end
    
    def set_color *args
      @shell.set_color(*args)
    end
    
    def get_services
      if options['config-file'] && !options['config-file'].empty?
        Service.add_file(options['config-file'])
      end
      
      ['Freyrfile','.freyrrc'].each do |f|
        Service.add_file(f)
      end
    end
  end
end