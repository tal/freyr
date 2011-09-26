require 'delegate'
require 'forwardable'
require 'logger'
require 'fileutils'

module Freyr
  extend self
  OUT = STDOUT.dup

  def logger
    @logger ||= Logger.new("/dev/null")
  end
  
  def logger= logger
    @logger = logger
  end
end

%w{version helpers service service_group command service_info pid_file pinger process_info}.each do |f|
  require File.expand_path(File.dirname(__FILE__)+"/freyr/#{f}.rb")
end
