module Freyr
  
  
  class Runner
    attr_reader :name, :dir, :variants, :variant_values
    def initialize(name, args={}, &block)
      @name = name
      @dir = args[:dir]
      
      instance_eval(&block)
    end
    
    def inspect
      %Q{#<Freyr::Runner name: #{name} >}
    end
    
    def dir d=nil
      d.nil? ? @dir : @dir = d
    end
    
    def start command=nil
      if command
        @start_command = command
      else
        @start_command
      end
    end
    
    def stop command=nil
      if command
        @stop_command = command
      else
        @stop_command
      end
    end
    
    def restart command=nil
      if command
        @restart_command = command
      else
        @restart_command
      end
    end
    
    def kill_signal sig=nil
      if sig
        @kill_signal = sig
      else
        @kill_signal
      end
    end
    
    def restart_signal sig=nil
      if sig
        @restart_signal = sig
      else
        @restart_signal
      end
    end
    
    def variant name, val = nil, &block
      @variants ||= []
      @variant_values = val
      if val
        val.each do |i|
          args = {name => i, :multi => true}
          @variants << Variant.new(self, name, args, &block)
        end
      else
        @variants << Variant.new(self, name, &block)
      end
    end
    
    class << self
      def s
        @all_runners||=[]
      end
      
      def add_file f
        s
        @all_runners += from_file(f)
      end
      
      def find_from_id i
        runner, variant, iteration = i.split(':')
        
        runner = @all_runners.find do |r|
          r.name.to_s == runner
        end
        
        if runner
          var = runner.variants.find do |v|
            v.name.to_s == variant
          end
          
          var.iteration = iteration if var
          var
        end
      end
      
      def from_file file
        @add_runners = []
        @dir = File.dirname(file)
        instance_eval(File.open(file).read)
        @add_runners
      end
      
    private
      
      def run name, &block
        @add_runners << Runner.new(name,{:dir => @dir},&block)
      end
      
    end
  end
  
  class Variant
    attr_reader :name, :runner, :iteration, :multi
    def initialize(runner,name,args={},&block)
      @name = name
      @multi = args.delete(:multi)
      @replacement_map = args
      @runner = runner
      instance_eval(&block) if block
    end
    
    def env  vars
      @env = vars
    end
    
    def method_missing meth, val
      @replacement_map[meth] = val
    end
    
    def id
      str = "#{@runner.name}:#{@name}"
      
      if v = @replacement_map[@name.to_sym] || v = @iteration
        str << ":#{v}"
      end
      
      str
    end
    
    def start_command
      cmd = String.new
      if @runner.dir
        cmd << "cd #{@runner.dir} && "
      end
      
      if @env
        vars = @env.collect {|key,value| "#{key.upcase}=\"#{value}\""}
        cmd << vars.join(' ')
        cmd << ' '
      end
      
      cmd << @runner.start
      
      @replacement_map.each do |key,value|
        cmd.gsub!("{{#{key}}}", value.to_s)
      end
      
      cmd
    end
    
    def iteration=(i)
      if multi
        puts runner.variant_values.inspect
        raise ArgumentError, 'unable to find specified variant' if runner.variant_values && !runner.variant_values.include?(i)
        @replacement_map[name] = i
      end
      
      @iteration = i
    end
    
    def stop_command
      return unless runner.stop
      cmd = String.new
      if @runner.dir
        cmd << "cd #{@runner.dir} && "
      end
      
      cmd << @runner.stop
      
      @replacement_map.each do |key,value|
        cmd.gsub!("{{#{key}}}", value.to_s)
      end
      
      cmd
    end
    
    def thread
      @thread ||= Freyr::Thread.find(id)
    end
    
    def stop(iteration = nil)
      if stop_command
        `#{stop_command}`
      else
        if runner.kill_signal
          thread.kill(runner.kill_signal)
        else
          thread.kill
        end
      end
    end
    
    def start
      puts %Q{Running #{id} - #{start_command.inspect}}
      Freyr::Thread.new_instance(:id => id) do
        exec start_command}
      end
    end
    
    def inspect
      %Q{#<Freyr::Variant id: #{id} >}
    end
    
  end
  
end
