module PredictionIO

  # This class handles multithreading and asynchronous requests transparently for the REST client.
  class Connection

    # Number of pending asynchronous request and response packages.
    attr_reader :packages

    # Number of connections active
    attr_reader :connections

    # Timeout in seconds
    attr_reader :timeout

    # Spawns a number of threads with persistent HTTP connection to the specified URI.
    # Sets a default timeout of 60 seconds.
    def initialize(uri, threads = 1, timeout = 60)
      @packages = Queue.new
      @counter_lock = Mutex.new
      @connections = 0
      @timeout = timeout
      threads.times do
        Thread.new do
          begin
            Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
              @counter_lock.synchronize do
                @connections += 1
              end
              catch(:exit) do
                http.read_timeout = @timeout
                loop do
                  package = @packages.pop
                  request = package[:request]
                  response = package[:response]
                  case package[:method]
                  when 'get'
                    http_req = Net::HTTP::Get.new("#{uri.path}#{request.qpath}")
                    begin
                      response.set(http.request(http_req))
                    rescue Exception => details
                      response.set(details)
                    end
                  when 'post'
                    if request.params.is_a?(Hash)
                      http_req = Net::HTTP::Post.new("#{uri.path}#{request.path}")
                      http_req.set_form_data(request.params)
                    else
                      http_req = Net::HTTP::Post.new("#{uri.path}#{request.path}", initheader = { 'Content-Type' => 'application/json; charset=utf-8' })
                      http_req.body = request.params
                    end
                    begin
                      response.set(http.request(http_req))
                    rescue Exception => details
                      response.set(details)
                    end
                  when 'delete'
                    http_req = Net::HTTP::Delete.new("#{uri.path}#{request.qpath}")
                    begin
                      response.set(http.request(http_req))
                    rescue Exception => details
                      response.set(details)
                    end
                  when 'exit'
                    @counter_lock.synchronize do
                      @connections -= 1
                    end
                    throw :exit
                  end
                end
              end
            end
          rescue Exception => detail
            @counter_lock.synchronize do
              if @connections == 0 then
                # Use non-blocking pop to avoid dead-locking the current
                # thread when there is no request, and give it a chance to re-connect.
                begin
                  package = @packages.pop(true)
                  response = package[:response]
                  response.set(detail)
                rescue Exception
                end
              end
            end
            sleep(1)
            retry
          end
        end
      end
    end

    # Create an asynchronous request and response package, put it in the pending queue, and return the response object.
    def request(method, request)
      response = AsyncResponse.new(request)
      @packages.push(method: method, request: request, response: response)
      response
    end

    # Shortcut to create an asynchronous GET request with the response object returned.
    def aget(areq)
      request('get', areq)
    end

    # Shortcut to create an asynchronous POST request with the response object returned.
    def apost(areq)
      request('post', areq)
    end

    # Shortcut to create an asynchronous DELETE request with the response object returned.
    def adelete(areq)
      request('delete', areq)
    end
  end
end
