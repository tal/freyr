require 'forwardable'
require 'logger'

module Freyr
  def self.logger
    @logger ||= Logger.new("/dev/null")
  end
  
  def self.logger= logger
    @logger = logger
  end
end

%w{version service_group service command service_info pinger process_info}.each do |f|
  require File.expand_path(File.dirname(__FILE__)+"/freyr/#{f}.rb")
end
