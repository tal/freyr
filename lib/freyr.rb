require 'forwardable'

module Freyr
  VERSION = File.open(File.expand_path(File.dirname(__FILE__)+'/../VERSION')).read
end

%w{service_info service command pinger}.each do |f|
  require File.expand_path(File.dirname(__FILE__)+"/freyr/#{f}.rb")
end
