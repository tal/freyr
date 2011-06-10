module Freyr
  class ProcessInfoList
    def initialize
      ps = `ps aux`.chomp.split("\n")
      ps.shift
      
      @processes = {}
      ps.each do |proc|
        proc = proc.split(/\s+/)
        p = ProcessInfo.new
        p.user = proc.shift
        p.pid  = proc.shift
        p.cpu  = proc.shift
        p.mem  = proc.shift
        p.vsz  = proc.shift
        p.rss  = proc.shift
        p.tt   = proc.shift
        p.stat = proc.shift
        p.started = proc.shift
        p.time = proc.shift
        p.cmd  = proc.join(' ')
        
        @processes[p.pid.to_i] = p
      end
    end
    
    def [] pid
      @processes[pid.to_i]
    end
    
  end
end
