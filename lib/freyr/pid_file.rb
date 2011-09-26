module Freyr
  class PidFile
    def initialize path, procname=nil
      @path = path
      @procname = procname
    end

    def process_info
      @proces_info ||= ProcessInfo.new(@pid) if @pid
    end

    def alive?
      return unless pid
      Process.getpgid(pid)
      true
    rescue Errno::ESRCH
      false
    end

    def pid_from_file
      return unless File.exist?(@path)
      p = File.open(@path).read.chomp
      p ? p.to_i : nil
    end

    def pid force=false
      if !force && File.exist?(@path)
        pid_from_file
      elsif @procname
        pid_from_procname
      else
        pid_from_file
      end
    end

    def pid_from_procname force=false
      pids = PidFile.pid_command_hash(force)
      
      if procline = pids.keys.find {|p| p.match(@procname)}
        pids[procline]
      end
    end

    def wait_for_pid wait = 40, interval=0.2
      OUT.puts "Waiting #{wait}s for pid from match of #{@procname}"

      start = Time.now

      until (pid = pid_from_procname(true)) || (Time.now-start) > wait
        OUT.print '.';OUT.flush
        sleep(interval)
      end

      raise Timeout, "\n Couldn't find pid after" unless pid
      OUT.puts '*'
      pid
    end

    class << self

      def pid_command_hash force=false
        @pid_command_hash = nil if force
        @pid_command_hash ||= `ps -eo pid,command`.split("\n").inject({}) do |r, pid|
          if m = pid.match(/^\s*(\d+)\s(.+)$/)
            r[m[2]] = m[1].to_i
          end
          r
        end
      end

    end
  end
end
