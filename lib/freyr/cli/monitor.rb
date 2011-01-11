module Freyr
  class CLI < Thor
    
    desc 'list', 'lists all available services:'
    def list
      strs = list_all_services
      
      if strs.empty?
        say "No services available", :red
      else
        say "List of all available services (#{set_color('*', :yellow)} denotes root proc)"
        strs.each_with_index do |s,i|
          say s
        end
      end
    end
    
    desc 'tail', 'read stdout of the service'
    method_option :lines, :type => :numeric, :default => 50, :desc => 'Number of lines to show on initial tail'
    method_option :'no-follow', :type => :boolean, :default => false, :desc => 'Disable auto follow, just print tail and exit'
    def tail(name)
      services = get_from_name(name)
      if !services.empty?
        
        services.first.tail!(options.lines, !options['no-follow'])
      else
        say "Can't find the #{name} service", :red
      end
    end
    
    
  end
end