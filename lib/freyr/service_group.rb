module Freyr
  class ServiceGroup < Array
    
    def initialize(*args)
      super(*args)
    end
    
    def find_by_name(n)
      find {|s| s.name == n}
    end
    
    # Take care this can make a stack overflow
    def run
      return [] if empty?
      
      needs_to_run = ServiceGroup.new
      
      kill = false
      names = []
      
      each do |svc|
        
        unless svc.dependencies.empty?
          if n = svc.dependencies.find {|s| !Service.alive?(s)}
            if find_by_name(n)
              needs_to_run << svc
            elsif s = Service[n].first
              needs_to_run << s
              needs_to_run << svc
            else
              puts "Can't run #{svc.name} because dependency #{n} cannot be found"
              kill = true
            end
            
            next
          end
        end
        
        pid = svc.start!
        names << svc.name if pid
      end
      
      names += needs_to_run.run unless kill
      names
    end
    
    def stop
      changed_names = collect {|s| s.name if s.alive?}.compact
      each do |svc|
        svc.stop!
      end
      
      changed_names
    end
    
    def restart
      names = collect {|s| s.name}
      
      each do |s|
        s.restart!
        names.delete(s.name)
      end
      
      names
    end
    
  end
end
