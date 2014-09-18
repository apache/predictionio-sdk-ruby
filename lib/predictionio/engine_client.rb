# Ruby SDK for convenient access of PredictionIO Output API.
#
# Author::    PredictionIO Team (support@prediction.io)
# Copyright:: Copyright (c) 2014 TappingStone, Inc.
# License::   Apache License, Version 2.0

require 'predictionio/async_request'
require 'predictionio/async_response'
require 'predictionio/connection'

module PredictionIO
  # This class contains methods that interface with PredictionIO Engine
  # Instances that are trained from PredictionIO built-in Engines.
  #
  # Many REST request methods support optional arguments. They can be supplied
  # to these methods as Hash'es. For a complete reference, please visit
  # http://prediction.io.
  #
  # == High-performance Asynchronous Backend
  #
  # All REST request methods come in both synchronous and asynchronous flavors.
  # Both flavors accept the same set of arguments. In addition, all synchronous
  # request methods can instead accept a PredictionIO::AsyncResponse object
  # generated from asynchronous request methods as its first argument. In this
  # case, the method will block until a response is received from it.
  #
  # Any network reconnection and request retry is automatically handled in the
  # background. Exceptions will be thrown after a request times out to avoid
  # infinite blocking.
  #
  # == Installation
  # The easiest way is to use RubyGems:
  #     gem install predictionio
  #
  # == Synopsis
  # In most cases, using synchronous methods. If you have a special performance
  # requirement, you may want to take a look at asynchronous methods.
  #
  # === Instantiate PredictionIO Engine Client
  #     # Include the PredictionIO SDK
  #     require 'predictionio'
  #
  #     client = PredictionIO::EngineClient.new
  #
  # === Send a Query to Retrieve Predictions
  #     # PredictionIO call to record the view action
  #     begin
  #       result = client.query('uid' => 'foobar')
  #     rescue NotFoundError => e
  #       ...
  #     rescue BadRequestError => e
  #       ...
  #     rescue ServerError => e
  #       ...
  #     end
  class EngineClient
    # Raised when an event is not created after a synchronous API call.
    class NotFoundError < StandardError; end

    # Raised when the query is malformed.
    class BadRequestError < StandardError; end

    # Raised when the Engine Instance returns a server error.
    class ServerError < StandardError; end

    # Create a new PredictionIO Event Client with defaults:
    # - 1 concurrent HTTP(S) connections (threads)
    # - API entry point at http://localhost:7070 (apiurl)
    # - a 60-second timeout for each HTTP(S) connection (thread_timeout)
    def initialize(threads = 1, apiurl = 'http://localhost:8000',
                   thread_timeout = 60)
      @http = PredictionIO::Connection.new(URI(apiurl), threads, thread_timeout)
    end

    # Returns the number of pending requests within the current client.
    def pending_requests
      @http.packages.size
    end

    # Returns PredictionIO's status in string.
    def get_status
      status = @http.aget(PredictionIO::AsyncRequest.new('/')).get
      begin
        status.body
      rescue
        status
      end
    end

    protected

    # Internal helper method. Do not call directly.
    def sync_events(sync_m, *args)
      if args[0].is_a?(PredictionIO::AsyncResponse)
        response = args[0].get
      else
        response = send(sync_m, *args).get
      end
      if response.is_a?(Net::HTTPOK)
        return JSON.parse(response.body)
      else
        begin
          msg = response.body
        rescue
          raise response
        end
        if response.is_a?(Net::HTTPBadRequest)
          fail BadRequestError, msg
        elsif response.is_a?(Net::HTTPNotFound)
          fail NotFoundError, msg
        elsif response.is_a?(Net::HTTPServerError)
          fail ServerError, msg
        else
          fail msg
        end
      end
    end

    public

    # :category: Asynchronous Methods
    # Asynchronously sends a query and returns PredictionIO::AsyncResponse
    # object immediately.
    #
    # Corresponding REST API method: POST /
    #
    # See also #send_query.
    def asend_query(query)
      @http.apost(PredictionIO::AsyncRequest.new('/', query.to_json))
    end

    # :category: Synchronous Methods
    # Synchronously sends a query and block until predictions are received.
    #
    # See also #asend_query.
    #
    # call-seq:
    # send_query(data)
    # send_query(async_response)
    def send_query(*args)
      sync_events(:asend_query, *args)
    end
  end
end
