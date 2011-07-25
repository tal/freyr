module Freyr
  class CLI < Thor
    
    desc 'list', 'lists all available services:'
    method_option :ping, :type => :boolean, :default => false, :aliases => '-p', :desc => 'also ping each service which can ping'
    method_option :info, :type => :boolean, :default => false, :aliases => '-i', :desc => 'also get cpu and memory info'
    def list
      strs = list_all_services(:ping => options.ping?, :procinfo => options.info?)
      
      if strs.empty?
        say "No services available", :red
      else
        say "List of all available services (#{set_color('*', :yellow)} denotes root proc)"
        strs.each_with_index do |s,i|
          say s
        end
      end
    end
    
    desc 'tail [SERVICE=dirname]', 'read stdout of the service'
    method_option :lines, :type => :numeric, :default => 50, :desc => 'Number of lines to show on initial tail'
    method_option :'no-follow', :type => :boolean, :default => false, :desc => 'Disable auto follow, just print tail and exit'
    def tail(name=nil)
      services = get_from_name(name)
      if !services.empty?
        Freyr.logger.debug('tail args') {"Lines: #{options.lines}, following: #{!options['no-follow']}"}
        Freyr.logger.debug('tailing service') {services.first.inspect}
        services.first.tail!(options.lines, !options['no-follow'])
      else
        say "Can't find the #{name} service", :red
      end
    end
    
    desc 'ping', 'see the response from pinging the url'
    def ping(name=nil)
      service = get_from_name(name).first
      
      if service
        if service.ping
          pinger = Pinger.new(service)
          resp = pinger.ping
          if pinger.success?
            say "Up and running", :green
          elsif pinger.server_error?
            say "500 Error"
          elsif resp
            say "Returned #{resp.code} code", :red
          else
            say "Couldn't reach service", :red
          end
        else
          say 'No url to ping for this service'
        end
      else
        say "Can't find the #{name} service", :red
      end
    end
    
  end
end