require 'net/http'

module Freyr
  class Pinger
    attr_reader :url
    attr_reader :time
    attr_reader :response
    
    def initialize(command)
      @command = command
      @url = command.ping
    end
    
    def uri
      @uri ||= URI.parse(url)
    end
    
    def ping
      t = Time.now
      @response = Net::HTTP.get_response(uri)
      @time = Time.now-t
      @response
    end
    
    def success?
      response.is_a?(Net::HTTPSuccess)
    end
    
    def server_error?
      response.is_a?(Net::HTTPInternalServerError)
    end
    
    def server_probably_launched?
      success? || server_error?
    end
    
  end
end