require 'forwardable'

module Freyr
  VERSION = File.open(File.expand_path(File.dirname(__FILE__)+'/../VERSION')).read
end

%w{service_info service_group service command pinger process_info process_info_list}.each do |f|
  require File.expand_path(File.dirname(__FILE__)+"/freyr/#{f}.rb")
end
