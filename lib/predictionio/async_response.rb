require 'thread'

module PredictionIO
  # This class encapsulates an asynchronous response that will block the caller until the response is available.
  class AsyncResponse

    # The PredictionIO::AsyncRequest instance that created the current PredictionIO::AsyncResponse instance.
    attr_reader :request

    # Create the response by saving the request, and optionally the Net::HTTPResponse object.
    def initialize(request, response = nil)
      @request = request
      @response = Queue.new
      set(response) if response
    end

    # Save a Net::HTTPResponse instance to the current instance.
    # This will unblock any caller that called #get.
    def set(response)
      @response.push(response)
    end

    # Get the Net::HTTPResponse instance. This will block if the response is not yet available.
    def get
      @response.pop
    end
  end
end
