require "yaml"

module Freyr
  #
  # This is based VERY heavily on the code from Titan::Thread
  #
  class Thread
    
    FREYR_PIDS = ENV['USER'] == 'root' ? '/var/run/freyr' : File.expand_path('.freyr', '~')
    
    if !File.exist?(FREYR_PIDS)
      Dir.mkdir(FREYR_PIDS)
    elsif !File.directory?(FREYR_PIDS)
      File.delete(FREYR_PIDS)
      Dir.mkdir(FREYR_PIDS)
    end
    
    attr_reader :id, :pid
    
    #
    # Creates a new daemonized thread
    #
    def initialize(options = {}, &block)
      @id = options[:id] || object_id
      
      if block
        @pid  = Process.fork do
          $0 = @id.to_s
          # ignore interrupts
          Signal.trap('HUP', 'IGNORE')
          # execute the actual programm
          block.call
          # TODO: reap this pid file
          # exit the forked process cleanly
          Kernel.exit!
        end
        
        Process.detach(@pid)
        save
      elsif options[:pid]
        @pid = options[:pid].to_i
        save
      else
        raise ArgumentError, "No existing thread of ID: #{@id}" unless File.exist?(pid_file)
        @pid = read_pid
      end
    end
    
    def pid_file
      File.join(FREYR_PIDS,"#{@id}.pid")
    end
    
    def read_pid
      p = File.open(pid_file).read
      p ? p.to_i : nil
    end
    
    def save
      if File.exist?(pid_file)
        old_pid = read_pid
        begin
          Process.kill('KILL', old_pid) if old_pid && old_pid.to_s != @pid.to_s
        rescue Errno::ESRCH
        end
      end
      
      File.open(pid_file, 'w') {|f| f.write(@pid)}
    end
    
    def delete_if_dead
      File.delete(pid_file) unless alive?
    end
    
    #
    # Kills the daemonized thread
    # @param [String] Signal to send to the process. Eg: 'KILL','QUIT','TERM','INT', 'USR1'
    #
    def kill(sig='KILL')
      result = Process.kill(sig, @pid)
      # TODO: Handle reaping of pid file for when killing process takes a little bit.
      delete_if_dead
      result
    end

    #
    # Returns whether the thread is alive or not
    #
    def alive?
      Process.getpgid(@pid)
      true
    rescue Errno::ESRCH
      false
    end

    class << self
      
      #
      # Returns a thread that has the given id
      #
      def find(id)
        new(:id => id)
      rescue ArgumentError
        nil
      end

      def kill(id,sig='KILL')
        thread = find(id)
        thread.kill(sig) if thread
      end

      #
      # Returns all Freyr-managed threads
      #
      def all
        files = Dir[File.join(FREYR_PIDS,'**','*.pid')]
        
        files.collect { |file_name| Thread.new(:id => File.basename(file_name, '.pid')) }
      end

      def remove_dead_threads
        all.each { |thread| thread.delete_if_dead }
      end
      
      def new_instance(options = {}, &block)
        raise ArgumentError, 'id ' unless options[:id]
        
        unless options[:id].split(':').size == 3
          existing = Dir[File.join(FREYR_PIDS,'**',"#{options[:id]}*.pid")]
          
          if existing.empty?
            new_num = 1
          else
            nums = existing.collect do |filename|
              filename.match(/(\d+)\.pid/i)[1].to_i
            end
            
            new_num = nums.sort!.last + 1
          end
          
          options[:id] = "#{options[:id]}:#{new_num}"
        end
        # puts options.inspect
        new(options,&block)
      end
    end
  end
end
