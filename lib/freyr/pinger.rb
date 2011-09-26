require 'net/http'

module Freyr
  class Pinger
    # URL to ping
    attr_reader :url
    # Time that the ping took
    attr_reader :time
    # Response object
    attr_reader :response
    
    def initialize(service)
      @service = service
      @url = service.info.ping
    end

    def wait_for_resp wait=40, interval = 0.6, &blk
      OUT.puts "\nWaiting for response from #{url}"
      start = Time.now

      blk ||= lambda {true}

      begin
        OUT.print '.'; OUT.flush
        ping
        sleep(interval)
      end until server_probably_launched? || (Time.now-start) > wait || !blk.call

      if blk.call
        if response
          OUT.puts '*', "Last response received with code #{response.code}"
        else
          OUT.puts 'x', "Couldn't reach #{@service.name} service"
        end
      else
        OUT.puts 'x',"Service died durring launch"
      end
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
      response.is_a?(Net::HTTPSuccess) || response.is_a?(Net::HTTPRedirection)
    end
    
    # Did the response recieve a 500 error
    def server_error?
      response.is_a?(Net::HTTPInternalServerError)
    end
    
    # Did it receive 2xx or 500
    def server_probably_launched?
      success? || server_error?
    end
    
  end
end