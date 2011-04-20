require 'thor'
%w{launching management monitor helpers}.each do |f|
  require File.expand_path(File.dirname(__FILE__)+"/cli/#{f}.rb")
end

module Freyr
  class CLI < Thor
    include Thor::Actions
    
    default_task :list
    class_option :'config-file', :desc => 'config file to use', :type => :string
    class_option :'ignore-local', :desc => "don't use the local Freyrfile or .freyrrc", :type => :boolean, :default => false
    class_option :namespace, :type => :string, :desc => 'namespace to look in'
    map "-v" => :version
    
    desc 'version', 'displays current gem version'
    def version
      say Freyr::VERSION
    end
    
  end
end
