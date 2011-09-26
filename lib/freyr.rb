require 'delegate'
require 'forwardable'
require 'logger'
require 'fileutils'
require 'tsort'

module Freyr
  extend self
  OUT = STDOUT.dup

  def logger
    @logger ||= begin 
      log = Logger.new(STDOUT)
      log.level = Logger::FATAL
      log.formatter = proc do |severity, datetime, progname, msg|
        %Q{#{severity.chars.first}: #{[progname,msg].compact.join(' - ')}\n}
      end
      log
    end
  end
  
  def logger= logger
    @logger = logger
  end
end

if ARGV.include?('--trace')
  Freyr.logger.level = Logger::DEBUG
end

%w{version helpers service service_group command service_info pid_file pinger process_info}.each do |f|
  require File.expand_path(File.dirname(__FILE__)+"/freyr/#{f}.rb")
end
