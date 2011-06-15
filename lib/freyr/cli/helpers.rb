module Freyr
  class CLI < Thor
    
    def initialize(*)
      super
      get_services
    end
    
  private
    # Ugh, this is ugly, colorizing stuff is rough
    def list_all_services(args={})
      args[:highlight_name] = (args[:highlight_name]||[]).collect {|n| n.to_s}
      args[:highlight_state] = (args[:highlight_state]||[]).collect {|n| n.to_s}
      
      max_length = 0
      
      groups_join = '|'
      
      lengths = Service.s.collect do |s|
        n = "   #{s.name}(#{s.groups.join(groups_join)})"
        max_length = n.length if n.length > max_length
        n.length
      end
      
      max_length += 3 # min distance between name and group
      
      strs = []
      Service.s.each_with_index do |s,i|
        str = '  '
        if s.sudo
          str << set_color('*', :yellow)
        else
          str << ' '
        end
        
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
            str << groups_join
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
        
        if args[:ping] && s.alive? && pinger = s.ping!
          png = "(#{pinger.code})"
          if pinger.success?
            png = set_color(png, :green, false)
          elsif pinger.server_error?
            png = set_color(png, :yellow, true)
          else
            png = set_color(png, :red, true)
          end
          
          str << png
        elsif args[:ping]
          str << ' '*'(123)'.size
        end
        
        if args[:procinfo]
          begin
            pid = s.command.pid
            
            proc = ProcessInfo[pid]
            
            str << " CPU: #{proc.pcpu}% - MEM: #{proc.mem_in_mb.to_i}mb" if proc
          # rescue => e
          end
        end
        
        str << "\n" #if str =~ /\s$/ # Thor's display only adds a new line if the last char isn't a space
        
        strs << str
      end
      
      strs
    end
    
    def set_color *args
      @shell.set_color(*args)
    end
    
    def get_from_name name
      group = ServiceGroup.new
      
      unless name
        s = Service.s.find {|svc| svc.dir == Dir.pwd}
        return group << s if s
      end
      
      if options.namespace && s = Service["#{options.namespace}:#{name}"].first
        group << s # only pickng one because if it's namespaced it's not a group
      else
        Service[name].each do |s|
          group << s
        end
      end
      
      group
    end
    
    def get_services
      if options['config-file'] && !options['config-file'].empty?
        if File.exist?(options['config-file'])
          Service.add_file(options['config-file'])
        else
          say("Can't find file #{options['config-file']}",:red) 
        end
      end
      
      ['Freyrfile','.freyrrc','~/.freyrrc'].each do |f|
        Service.add_file(f)
      end unless options['ignore-local']
    end
  end
end