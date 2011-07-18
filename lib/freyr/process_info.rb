module Freyr
  class ProcessInfo
    attr_reader :pid, :rss, :vsz, :pcpu, :pmem, :ruser, :command
    def initialize pid
      @pid = pid
    end
    
    def ps
      return if !pid || pid.to_s.empty?
      info = `ps p #{pid} -o pid,rss,vsz,pmem,pcpu,ruser,command`
      match = info.match(/#{pid}\s+(\d+)\s+(\d+)\s+([\d\.]+)\s+([\d\.]+)\s+(\w+)\s+(.+)/)
      return unless match
      @rss = match[1].to_i
      @vsz = match[2].to_i
      @pmem = match[3].to_f
      @pcpu = match[4].to_f
      @ruser = match[5]
      @command = match[6]
      info
    end
    
    def port
      `lsof -p #{pid} -P | egrep TCP.+LISTEN`.match(/\*:(\d+)/)[1].to_i
    rescue
      nil
    end
    
    def mem_in_mb
      @rss/1024.0
    end
    
    class << self
      def [] *args
        n = new(*args)
        n.ps ? n : nil
      end
    end
  end
end
