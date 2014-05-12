# Ruby SDK for convenient access of PredictionIO Output API.
#
# Author::    TappingStone (help@tappingstone.com)
# Copyright:: Copyright (c) 2013 TappingStone
# License::   Apache License, Version 2.0

require 'date'
require 'json'
require 'net/http'
require 'predictionio/async_request'
require 'predictionio/async_response'
require 'predictionio/connection'

# The PredictionIO module contains classes that provide convenient access of the PredictionIO output API over HTTP/HTTPS.
#
# To create an app and perform predictions, please download the PredictionIO suite from http://prediction.io.
#
# Most functionality is provided by the PredictionIO::Client class.
module PredictionIO

  # This class contains methods that access PredictionIO via REST requests.
  #
  # Many REST request methods support optional arguments.
  # They can be supplied to these methods as Hash'es.
  # For a complete reference, please visit http://prediction.io.
  #
  # == High-performance Asynchronous Backend
  #
  # All REST request methods come in both synchronous and asynchronous flavors.
  # Both flavors accept the same set of arguments.
  # In addition, all synchronous request methods can instead accept a PredictionIO::AsyncResponse object generated from asynchronous request methods as its first argument.
  # In this case, the method will block until a response is received from it.
  #
  # Any network reconnection and request retry is automatically handled in the background.
  # Exceptions will be thrown after a request times out to avoid infinite blocking.
  #
  # == Special Handling of Some Optional Arguments
  # Some optional arguments have additional special handling:
  # - For all requests that accept "itypes" as input, the value can be supplied as either an Array of String's, or a comma-delimited String.
  # - For all requests that accept "pio_latlng" as input, they will also accept "pio_latitude" and "pio_longitude".
  #   When these are supplied, they will override any existing "pio_latlng" value.
  # - All time arguments (e.g. t, pio_startT, pio_endT, etc) can be supplied as either a Time or Float object.
  #   When supplied as a Float, the SDK will interpret it as a UNIX UTC timestamp in seconds.
  #   The SDK will automatically round to the nearest millisecond, e.g. 3.14159 => 3.142.
  #
  # == Installation
  # The easiest way is to use RubyGems:
  #     gem install predictionio
  #
  # == Synopsis
  # The recommended usage of the SDK is to fire asynchronous requests as early as you can in your code,
  # and check results later when you need them.
  #
  # === Instantiate PredictionIO Client
  #     # Include the PredictionIO SDK
  #     require "predictionio"
  #
  #     client = PredictionIO::Client.new(<appkey>)
  #
  # === Import a User Record from Your App (with asynchronous/non-blocking requests)
  #
  #     #
  #     # (your user registration logic)
  #     #
  #
  #     uid = get_user_from_your_db()
  #
  #     # PredictionIO call to create user
  #     response = client.acreate_user(uid)
  #
  #     #
  #     # (other work to do for the rest of the page)
  #     #
  #
  #     begin
  #       # PredictionIO call to retrieve results from an asynchronous response
  #       result = client.create_user(response)
  #     rescue UserNotCreatedError => e
  #       log_and_email_error(...)
  #     end
  #
  # === Import a User Action (Rate) from Your App (with synchronous/blocking requests)
  #     # PredictionIO call to record the view action
  #     begin
  #       client.identify("foouser")
  #       result = client.record_action_on_item("rate", "baritem", "pio_rate" => 4)
  #     rescue U2IActionNotCreatedError => e
  #       ...
  #     end
  #
  # === Retrieving Top N Recommendations for a User
  #     # PredictionIO call to get recommendations
  #     client.identify("foouser")
  #     response = client.aget_itemrec_top_n("barengine", 10)
  #
  #     #
  #     # work you need to do for the page (rendering, db queries, etc)
  #     #
  #
  #     begin
  #       result = client.get_itemrec_top_n(response)
  #       # display results, store results, or your other work...
  #     rescue ItemRecNotFoundError => e
  #       # graceful error handling
  #     end
  #
  # === Retrieving Top N Similar Items for an Item
  #     # PredictionIO call to get similar items
  #     response = client.aget_itemsim_top_n("barengine", "fooitem", 10)
  #
  #     #
  #     # work you need to do for the page (rendering, db queries, etc)
  #     #
  #
  #     begin
  #       result = client.get_itemsim_top_n(response)
  #       # display results, store results, or your other work...
  #     rescue ItemSimNotFoundError => e
  #       # graceful error handling
  #     end

  class Client

    # Appkey can be changed on-the-fly after creation of the client.
    attr_accessor :appkey

    # Only JSON is currently supported as API response format.
    attr_accessor :apiformat

    # The UID used for recording user-to-item actions and retrieving recommendations.
    attr_accessor :apiuid

    # Raised when a user is not created after a synchronous API call.
    class UserNotCreatedError < StandardError; end

    # Raised when a user is not found after a synchronous API call.
    class UserNotFoundError < StandardError; end

    # Raised when a user is not deleted after a synchronous API call.
    class UserNotDeletedError < StandardError; end

    # Raised when an item is not created after a synchronous API call.
    class ItemNotCreatedError < StandardError; end

    # Raised when an item is not found after a synchronous API call.
    class ItemNotFoundError < StandardError; end

    # Raised when an item is not deleted after a synchronous API call.
    class ItemNotDeletedError < StandardError; end

    # Raised when ItemRec results cannot be found for a user after a synchronous API call.
    class ItemRecNotFoundError < StandardError; end

    # Raised when ItemRank results cannot be found for a user after a synchronous API call.
    class ItemRankNotFoundError < StandardError; end

    # Raised when ItemSim results cannot be found for an item after a synchronous API call.
    class ItemSimNotFoundError < StandardError; end

    # Raised when an user-to-item action is not created after a synchronous API call.
    class U2IActionNotCreatedError < StandardError; end

    # Create a new PredictionIO client with default:
    # - 10 concurrent HTTP(S) connections (threads)
    # - API entry point at http://localhost:8000 (apiurl)
    # - a 60-second timeout for each HTTP(S) connection (thread_timeout)
    def initialize(appkey, threads = 10, apiurl = "http://localhost:8000", thread_timeout = 60)
      @appkey = appkey
      @apiformat = "json"
      @http = PredictionIO::Connection.new(URI(apiurl), threads, thread_timeout)
    end

    # Returns the number of pending requests within the current client.
    def pending_requests
      @http.packages.size
    end

    # Returns PredictionIO's status in string.
    def get_status
      status = @http.aget(PredictionIO::AsyncRequest.new("/")).get()
      begin
        status.body
      rescue Exception
        status
      end
    end

    # :category: Asynchronous Methods
    # Asynchronously request to create a user and return a PredictionIO::AsyncResponse object immediately.
    #
    # Corresponding REST API method: POST /users
    #
    # See also #create_user.
    def acreate_user(uid, params = {})
      rparams = params
      rparams["pio_appkey"] = @appkey
      rparams["pio_uid"] = uid
      if params["pio_latitude"] && params["pio_longitude"]
        rparams["pio_latlng"] = "#{params["pio_latitude"]},#{params["pio_longitude"]}"
      end

      @http.apost(PredictionIO::AsyncRequest.new("/users.#{@apiformat}", rparams))
    end

    # :category: Synchronous Methods
    # Synchronously request to create a user and block until a response is received.
    #
    # See also #acreate_user.
    #
    # call-seq:
    # create_user(uid, params = {})
    # create_user(async_response)
    def create_user(*args)
      uid_or_res = args[0]
      if uid_or_res.is_a?(PredictionIO::AsyncResponse)
        response = uid_or_res.get
      else
        uid = uid_or_res
        response = acreate_user(*args).get
      end
      unless response.is_a?(Net::HTTPCreated)
        begin
          msg = response.body
        rescue Exception
          raise UserNotCreatedError, response
        end
        raise UserNotCreatedError, msg
      end
    end

    # :category: Asynchronous Methods
    # Asynchronously request to get a user and return a PredictionIO::AsyncResponse object immediately.
    #
    # Creation time of the user will be returned as a Time object.
    #
    # If the result contains a latlng key, both latitude and longitude will also be available as separate keys.
    #
    # Corresponding REST API method: GET /users/:uid
    #
    # See also #get_user.
    def aget_user(uid)
      @http.aget(PredictionIO::AsyncRequest.new("/users/#{uid}.#{@apiformat}",
                                                "pio_appkey" => @appkey,
                                                "pio_uid" => uid))
    end

    # :category: Synchronous Methods
    # Synchronously request to get a user and block until a response is received.
    #
    # Creation time of the user will be returned as a Time object.
    #
    # If the result contains a latlng key, both latitude and longitude will also be available as separate keys.
    #
    # See also #aget_user.
    #
    # call-seq:
    # get_user(uid)
    # get_user(async_response)
    def get_user(uid_or_res)
      if uid_or_res.is_a?(PredictionIO::AsyncResponse)
        response = uid_or_res.get
      else
        response = aget_user(uid_or_res).get
      end
      if response.is_a?(Net::HTTPOK)
        res = JSON.parse(response.body)
        if res["pio_latlng"]
          latlng = res["pio_latlng"]
          res["pio_latitude"] = latlng[0]
          res["pio_longitude"] = latlng[1]
        end
        res
      else
        begin
          msg = response.body
        rescue Exception
          raise UserNotFoundError, response
        end
        raise UserNotFoundError, msg
      end
    end

    # :category: Asynchronous Methods
    # Asynchronously request to delete a user and return a PredictionIO::AsyncResponse object immediately.
    #
    # Corresponding REST API method: DELETE /users/:uid
    #
    # See also #delete_user.
    def adelete_user(uid)
      @http.adelete(PredictionIO::AsyncRequest.new("/users/#{uid}.#{@apiformat}",
                                                   "pio_appkey" => @appkey,
                                                   "pio_uid" => uid))
    end

    # :category: Synchronous Methods
    # Synchronously request to delete a user and block until a response is received.
    #
    # See also #adelete_user.
    #
    # call-seq:
    # delete_user(uid)
    # delete_user(async_response)
    def delete_user(uid_or_res)
      if uid_or_res.is_a?(PredictionIO::AsyncResponse)
        response = uid_or_res.get
      else
        response = adelete_user(uid_or_res).get
      end
      unless response.is_a?(Net::HTTPOK)
        begin
          msg = response.body
        rescue Exception
          raise UserNotDeletedError, response
        end
        raise msg
      end
    end

    # :category: Asynchronous Methods
    # Asynchronously request to create an item and return a PredictionIO::AsyncResponse object immediately.
    #
    # Corresponding REST API method: POST /items
    #
    # See also #create_item.
    def acreate_item(iid, itypes, params = {})
      rparams = params
      rparams["pio_appkey"] = @appkey
      rparams["pio_iid"] = iid
      begin
        rparams["pio_itypes"] = itypes.join(",")
      rescue Exception
        rparams["pio_itypes"] = itypes
      end
      if params["pio_latitude"] && params["pio_longitude"]
        rparams["pio_latlng"] = "#{params["pio_latitude"]},#{params["pio_longitude"]}"
      end
      rparams["pio_startT"] = ((params["pio_startT"].to_r) * 1000).round(0).to_s if params["pio_startT"]
      rparams["pio_endT"]   = ((params["pio_endT"].to_r) * 1000).round(0).to_s if params["pio_endT"]

      @http.apost(PredictionIO::AsyncRequest.new("/items.#{@apiformat}", rparams))
    end

    # :category: Synchronous Methods
    # Synchronously request to create an item and block until a response is received.
    #
    # See #acreate_item for a description of other accepted arguments.
    #
    # call-seq:
    # create_item(iid, itypes, params = {})
    # create_item(async_response)
    def create_item(*args)
      iid_or_res = args[0]
      if iid_or_res.is_a?(PredictionIO::AsyncResponse)
        response = iid_or_res.get
      else
        response = acreate_item(*args).get
      end
      unless response.is_a?(Net::HTTPCreated)
        begin
          msg = response.body
        rescue Exception
          raise ItemNotCreatedError, response
        end
        raise ItemNotCreatedError, msg
      end
    end

    # :category: Asynchronous Methods
    # Asynchronously request to get an item and return a PredictionIO::AsyncResponse object immediately.
    #
    # Creation time of the user will be returned as a Time object.
    #
    # If the result contains a latlng key, both latitude and longitude will also be available as separate keys.
    #
    # Corresponding REST API method: GET /items/:iid
    #
    # See also #get_item.
    def aget_item(iid)
      @http.aget(PredictionIO::AsyncRequest.new("/items/#{iid}.#{@apiformat}",
                                                "pio_appkey" => @appkey,
                                                "pio_iid" => iid))
    end

    # :category: Synchronous Methods
    # Synchronously request to get an item and block until a response is received.
    #
    # Creation time of the item will be returned as a Time object.
    #
    # If the result contains a latlng key, both latitude and longitude will also be available as separate keys.
    #
    # See also #aget_item.
    #
    # call-seq:
    # get_item(iid)
    # get_item(async_response)
    def get_item(iid_or_res)
      if iid_or_res.is_a?(PredictionIO::AsyncResponse)
        response = iid_or_res.get
      else
        response = aget_item(iid_or_res).get
      end
      if response.is_a?(Net::HTTPOK)
        res = JSON.parse(response.body)
        if res["pio_latlng"]
          latlng = res["pio_latlng"]
          res["pio_latitude"] = latlng[0]
          res["pio_longitude"] = latlng[1]
        end
        if res["pio_startT"]
          startT = Rational(res["pio_startT"], 1000)
          res["pio_startT"] = Time.at(startT)
        end
        if res["pio_endT"]
          endT = Rational(res["pio_endT"], 1000)
          res["pio_endT"] = Time.at(endT)
        end
        res
      else
        begin
          msg = response.body
        rescue Exception
          raise ItemNotFoundError, response
        end
        raise ItemNotFoundError, msg
      end
    end

    # :category: Asynchronous Methods
    # Asynchronously request to delete an item and return a PredictionIO::AsyncResponse object immediately.
    #
    # Corresponding REST API method: DELETE /items/:iid
    #
    # See also #delete_item.
    def adelete_item(iid)
      @http.adelete(PredictionIO::AsyncRequest.new("/items/#{iid}.#{@apiformat}",
                                                   "pio_appkey" => @appkey,
                                                   "pio_iid" => iid))
    end

    # :category: Synchronous Methods
    # Synchronously request to delete an item and block until a response is received.
    #
    # See also #adelete_item.
    #
    # call-seq:
    # delete_item(iid)
    # delete_item(async_response)
    def delete_item(iid_or_res)
      if iid_or_res.is_a?(PredictionIO::AsyncResponse)
        response = iid_or_res.get
      else
        response = adelete_item(iid_or_res).get
      end
      unless response.is_a?(Net::HTTPOK)
        begin
          msg = response.body
        rescue Exception
          raise ItemNotDeletedError, response
        end
        raise ItemNotDeletedError, msg
      end
    end

    # Set the user ID for use in all subsequent user-to-item action recording and user recommendation retrieval.
    def identify(uid)
      @apiuid = uid
    end

    # :category: Asynchronous Methods
    # Asynchronously request to get the top n recommendations for a user from an ItemRec engine and return a PredictionIO::AsyncResponse object immediately.
    #
    # Corresponding REST API method: GET /engines/itemrec/:engine/topn
    #
    # See also #get_itemrec_top_n.
    def aget_itemrec_top_n(engine, n, params = {})
      rparams = Hash.new
      rparams["pio_appkey"] = @appkey
      rparams["pio_uid"] = @apiuid
      rparams["pio_n"] = n
      if params["pio_itypes"]
        if params["pio_itypes"].kind_of?(Array) && params["pio_itypes"].any?
          rparams["pio_itypes"] = params["pio_itypes"].join(",")
        else
          rparams["pio_itypes"] = params["pio_itypes"]
        end
      end
      if params["pio_latitude"] && params["pio_longitude"]
        rparams["pio_latlng"] = "#{params["pio_latitude"]},#{params["pio_longitude"]}"
      end
      rparams["pio_within"] = params["pio_within"] if params["pio_within"]
      rparams["pio_unit"] = params["pio_unit"] if params["pio_unit"]
      if params["pio_attributes"]
        if params["pio_attributes"].kind_of?(Array) && params["pio_attributes"].any?
          rparams["pio_attributes"] = params["pio_attributes"].join(",")
        else
          rparams["pio_attributes"] = params["pio_attributes"]
        end
      end
      @http.aget(PredictionIO::AsyncRequest.new("/engines/itemrec/#{engine}/topn.#{@apiformat}", rparams))
    end

    # :category: Synchronous Methods
    # Synchronously request to get the top n recommendations for a user from an ItemRec engine and block until a response is received.
    #
    # See #aget_itemrec_top_n for a description of special argument handling.
    #
    # call-seq:
    # get_itemrec_top_n(engine, n, params = {})
    # get_itemrec_top_n(async_response)
    def get_itemrec_top_n(*args)
      uid_or_res = args[0]
      if uid_or_res.is_a?(PredictionIO::AsyncResponse)
        response = uid_or_res
      else
        response = aget_itemrec_top_n(*args)
      end
      http_response = response.get
      if http_response.is_a?(Net::HTTPOK)
        res = JSON.parse(http_response.body)
        if response.request.params.has_key?('pio_attributes')
          attributes = response.request.params['pio_attributes'].split(',')
          list_of_attribute_values = attributes.map { |attrib| res[attrib] }
          res["pio_iids"].zip(*list_of_attribute_values).map { |v| Hash[(['pio_iid'] + attributes).zip(v)] }
        else
          res["pio_iids"]
        end
      else
        begin
          msg = response.body
        rescue Exception
          raise ItemRecNotFoundError, response
        end
        raise ItemRecNotFoundError, msg
      end
    end

    # :category: Asynchronous Methods
    # Asynchronously request to get the ranking for a user from an ItemRank engine and return a PredictionIO::AsyncResponse object immediately.
    #
    # Corresponding REST API method: GET /engines/itemrank/:engine/ranked
    #
    # See also #get_itemrank_ranked.
    def aget_itemrank_ranked(engine, iids, params = {})
      rparams = Hash.new
      rparams["pio_appkey"] = @appkey
      rparams["pio_uid"] = @apiuid
      if iids.kind_of?(Array) && iids.any?
        rparams["pio_iids"] = iids.join(",")
      else
        rparams["pio_iids"] = iids
      end
      if params["pio_attributes"]
        if params["pio_attributes"].kind_of?(Array) && params["pio_attributes"].any?
          rparams["pio_attributes"] = params["pio_attributes"].join(",")
        else
          rparams["pio_attributes"] = params["pio_attributes"]
        end
      end
      @http.aget(PredictionIO::AsyncRequest.new("/engines/itemrank/#{engine}/ranked.#{@apiformat}", rparams))
    end

    # :category: Synchronous Methods
    # Synchronously request to get the ranking for a user from an ItemRank engine and block until a response is received.
    #
    # See #aget_itemrank_ranked for a description of special argument handling.
    #
    # call-seq:
    # get_itemrank_ranked(engine, n, params = {})
    # get_itemrank_ranked(async_response)
    def get_itemrank_ranked(*args)
      uid_or_res = args[0]
      if uid_or_res.is_a?(PredictionIO::AsyncResponse)
        response = uid_or_res
      else
        response = aget_itemrank_ranked(*args)
      end
      http_response = response.get
      if http_response.is_a?(Net::HTTPOK)
        res = JSON.parse(http_response.body)
        if response.request.params.has_key?('pio_attributes')
          attributes = response.request.params['pio_attributes'].split(',')
          list_of_attribute_values = attributes.map { |attrib| res[attrib] }
          res["pio_iids"].zip(*list_of_attribute_values).map { |v| Hash[(['pio_iid'] + attributes).zip(v)] }
        else
          res["pio_iids"]
        end
      else
        begin
          msg = response.body
        rescue Exception
          raise ItemRankNotFoundError, response
        end
        raise ItemRankNotFoundError, msg
      end
    end

    # :category: Asynchronous Methods
    # Asynchronously request to get the top n similar items for an item from an ItemSim engine and return a PredictionIO::AsyncResponse object immediately.
    #
    # Corresponding REST API method: GET /engines/itemsim/:engine/topn
    #
    # See also #get_itemsim_top_n.
    def aget_itemsim_top_n(engine, iid, n, params = {})
      rparams = Hash.new
      rparams["pio_appkey"] = @appkey
      rparams["pio_iid"] = iid
      rparams["pio_n"] = n
      if params["pio_itypes"]
        if params["pio_itypes"].kind_of?(Array) && params["pio_itypes"].any?
          rparams["pio_itypes"] = params["pio_itypes"].join(",")
        else
          rparams["pio_itypes"] = params["pio_itypes"]
        end
      end
      if params["pio_latitude"] && params["pio_longitude"]
        rparams["pio_latlng"] = "#{params["pio_latitude"]},#{params["pio_longitude"]}"
      end
      rparams["pio_within"] = params["pio_within"] if params["pio_within"]
      rparams["pio_unit"] = params["pio_unit"] if params["pio_unit"]
      if params["pio_attributes"]
        if params["pio_attributes"].kind_of?(Array) && params["pio_attributes"].any?
          rparams["pio_attributes"] = params["pio_attributes"].join(",")
        else
          rparams["pio_attributes"] = params["pio_attributes"]
        end
      end
      @http.aget(PredictionIO::AsyncRequest.new("/engines/itemsim/#{engine}/topn.#{@apiformat}", rparams))
    end

    # :category: Synchronous Methods
    # Synchronously request to get the top n similar items for an item from an ItemSim engine and block until a response is received.
    #
    # See #aget_itemsim_top_n for a description of special argument handling.
    #
    # call-seq:
    # get_itemsim_top_n(engine, iid, n, params = {})
    # get_itemsim_top_n(async_response)
    def get_itemsim_top_n(*args)
      uid_or_res = args[0]
      if uid_or_res.is_a?(PredictionIO::AsyncResponse)
        response = uid_or_res
      else
        response = aget_itemsim_top_n(*args)
      end
      http_response = response.get
      if http_response.is_a?(Net::HTTPOK)
        res = JSON.parse(http_response.body)
        if response.request.params.has_key?('pio_attributes')
          attributes = response.request.params['pio_attributes'].split(',')
          list_of_attribute_values = attributes.map { |attrib| res[attrib] }
          res["pio_iids"].zip(*list_of_attribute_values).map { |v| Hash[(['pio_iid'] + attributes).zip(v)] }
        else
          res["pio_iids"]
        end
      else
        begin
          msg = response.body
        rescue Exception
          raise ItemSimNotFoundError, response
        end
        raise ItemSimNotFoundError, msg
      end
    end

    # :category: Asynchronous Methods
    # Asynchronously request to record an action on an item and return a PredictionIO::AsyncResponse object immediately.
    #
    # Corresponding REST API method: POST /actions/u2i
    #
    # See also #record_action_on_item.
    def arecord_action_on_item(action, iid, params = {})
      rparams = params
      rparams["pio_appkey"] = @appkey
      rparams["pio_action"] = action
      rparams["pio_uid"] = @apiuid
      rparams["pio_iid"] = iid
      rparams["pio_t"] = ((params["pio_t"].to_r) * 1000).round(0).to_s if params["pio_t"]
      if params["pio_latitude"] && params["pio_longitude"]
        rparams["pio_latlng"] = "#{params["pio_latitude"]},#{params["pio_longitude"]}"
      end
      @http.apost(PredictionIO::AsyncRequest.new("/actions/u2i.#{@apiformat}", rparams))
    end

    # :category: Synchronous Methods
    # Synchronously request to record an action on an item and block until a response is received.
    #
    # See also #arecord_action_on_item.
    #
    # call-seq:
    # record_action_on_item(action, iid, params = {})
    # record_action_on_item(async_response)
    def record_action_on_item(*args)
      action_or_res = args[0]
      if action_or_res.is_a?(PredictionIO::AsyncResponse)
        response = action_or_res.get
      else
        response = arecord_action_on_item(*args).get
      end
      unless response.is_a?(Net::HTTPCreated)
        begin
          msg = response.body
        rescue Exception
          raise U2IActionNotCreatedError, response
        end
        raise U2IActionNotCreatedError, msg
      end
    end
  end
end
