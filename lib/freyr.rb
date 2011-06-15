require 'forwardable'

module Freyr
  
end

%w{version service_info service_group service command pinger process_info}.each do |f|
  require File.expand_path(File.dirname(__FILE__)+"/freyr/#{f}.rb")
end
