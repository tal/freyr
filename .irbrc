require File.dirname(__FILE__) + '/lib/freyr.rb'
Freyr.logger = Logger.new(STDOUT)
include Freyr

Service.add_file("Freyrfile")
