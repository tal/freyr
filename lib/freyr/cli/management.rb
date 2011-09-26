module Freyr
  class CLI < Thor
    
    # desc 'update_pid [SERVICE=dirname]', 'Update pid from proc_match (good to use if service already launched)'
    # def update_pid(name=nil)
    #   services = get_from_name(name)
    #   if s = services.first
    #     if pid = s.command.update_pid
    #       say "Updated pid for "<< set_color(s.name,:blue) << ' to ' << set_color(pid,:red)
    #     elsif s.proc_match
    #       say "Couldn't find pid for process matcher #{s.proc_match.inspect}", :red
    #     else
    #       say "Service #{s.name} doesn't have a value for proc_match set.", :red
    #     end
    #   else
    #     say "Couldn't find service with name #{name}.", :red
    #   end
    # end
    
  end
end