require 'net/http'

module Freyr
  class Pinger
    # URL to ping
    attr_reader :url
    # Time that the ping took
    attr_reader :time
    # Response object
    attr_reader :response
    
    def initialize(command)
      @command = command
      @url = command.ping
    end
    
    # The URI object for the given URL
    def uri
      @uri ||= URI.parse(url)
    end
    
    # Send a ping to the url
    def ping
      t = Time.now
      @response = Net::HTTP.get_response(uri)
    rescue Errno::ECONNREFUSED
    ensure
      @time = Time.now-t
      @response
    end
    
    def code
      response.code if response
    end
    
    # Did the response recieve a success http code
    def success?
      response.is_a?(Net::HTTPSuccess)
    end
    
    # Did the response recieve a 500 error
    def server_error?
      response.is_a?(Net::HTTPInternalServerError)
    end
    
    # Did it recieve 2xx or 500
    def server_probably_launched?
      success? || server_error?
    end
    
  end
end