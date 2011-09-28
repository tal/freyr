module Freyr
  module RVM
    extend self

    def installed? ruby=nil
      return !`which rvm`.empty? unless ruby

      ruby, gemset = ruby.split('@')
      if rubies.include? ruby
        gemset ? gemsets_for(ruby).include?(gemset) : true
      else
        false
      end
    end

    def rubies
      @rubies ||= `rvm list strings`.chomp.split("\n")
    end

    def gemsets_for ruby
      @gemsets_for ||= Hash.new do |h,ruby|
        output = `rvm #{ruby} exec rvm gemset list strings`.chomp.split("\n")
        h[ruby] = output.collect do |line|
          line.strip.sub(/\s\(.+\)/,'')
        end.compact
      end
      @gemsets_for[ruby]
    end
  end
end
