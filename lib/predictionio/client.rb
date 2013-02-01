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
  # - For all requests that accept "latlng" as input, they will also accept "latitude" and "longitude".
  #   When these are supplied, they will override any existing "latlng" value.
  # - All time arguments (e.g. t, startT, endT, etc) can be supplied as either a Time or Float object.
  #   When supplied as a Float, the SDK will interpret it as a UNIX UTC timestamp in seconds.
  #   The SDK will automatically round to the nearest millisecond, e.g. 3.14159 => 3.142.
  #
  # == Installation
  # Download the PredictionIO Ruby Gem from http://prediction.io
  #     gem install predictionio-0.1.0.gem
  #
  # == Synopsis
  # The recommended usage of the SDK is to fire asynchronous requests as early as you can in your code,
  # and check results later when you need them.
  #
  # === Instantiate PredictionIO Client
  #     # Include the PredictionIO SDK
  #     require "PredictionIO"
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
  # === Import a User Action (View) form Your App (with synchronous/blocking requests)
  #     # PredictionIO call to record the view action
  #     begin
  #       result = client.user_view_item(4, 15)
  #     rescue U2IActionNotCreatedError => e
  #       ...
  #     end
  #
  # === Retrieving Top N Recommendations for a User
  #     # PredictionIO call to get recommendations
  #     response = client.aget_recommendation(4, 10)
  #
  #     #
  #     # work you need to do for the page (rendering, db queries, etc)
  #     #
  #
  #     begin
  #       result = client.get_recommendations(response)
  #       # display results, store results, or your other work...
  #     rescue RecommendationsNotFoundError => e
  #       # graceful error handling
  #     end

  class Client

    # Appkey can be changed on-the-fly after creation of the client.
    attr_accessor :appkey

    # API version can be changed on-the-fly after creation of the client.
    attr_accessor :apiversion

    # Only JSON is currently supported as API response format.
    attr_accessor :apiformat

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

    # Raised when an user-to-item action is not created after a synchronous API call.
    class U2IActionNotCreatedError < StandardError; end

    # Create a new PredictionIO client with default:
    # - API entry point at http://localhost:8000
    # - API return data format of json
    # - 10 concurrent HTTP(S) connections
    def initialize(appkey, threads = 10, apiurl = "http://localhost:8000", apiversion = "")
      @appkey = appkey
      @apiversion = apiversion
      @apiformat = "json"
      @http = PredictionIO::Connection.new(URI(apiurl), threads)
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
      rparams["appkey"] = @appkey
      rparams["uid"] = uid
      if params["latitude"] != nil && params["longitude"] != nil then
        rparams["latlng"] = "#{params["latitude"]},#{params["longitude"]}"
      end

      @http.apost(PredictionIO::AsyncRequest.new(versioned_path("/users.#{@apiformat}"), rparams))
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
      if uid_or_res.is_a?(PredictionIO::AsyncResponse) then
        uid = uid_or_res.request.params["uid"]
        response = uid_or_res.get
      else
        uid = uid_or_res
        response = acreate_user(*args).get
      end
      unless response.is_a?(Net::HTTPCreated) then
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
      @http.aget(PredictionIO::AsyncRequest.new(versioned_path("/users/#{uid}.#{@apiformat}"),
                                            "appkey" => @appkey,
                                            "uid" => uid))
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
      if uid_or_res.is_a?(PredictionIO::AsyncResponse) then
        response = uid_or_res.get
      else
        response = aget_user(uid_or_res).get
      end
      if response.is_a?(Net::HTTPOK) then
        res = JSON.parse(response.body)
        ct = Rational(res["ct"], 1000)
        res["ct"] = Time.at(ct)
        if res["latlng"] != nil then
          latlng = res["latlng"]
          res["latitude"] = latlng[0]
          res["longitude"] = latlng[1]
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
      @http.adelete(PredictionIO::AsyncRequest.new(versioned_path("/users/#{uid}.#{@apiformat}"),
                                               "appkey" => @appkey,
                                               "uid" => uid))
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
      if uid_or_res.is_a?(PredictionIO::AsyncResponse) then
        response = uid_or_res.get
      else
        response = adelete_user(uid_or_res).get
      end
      unless response.is_a?(Net::HTTPOK) then
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
      rparams["appkey"] = @appkey
      rparams["iid"] = iid
      begin
        rparams["itypes"] = itypes.join(",")
      rescue Exception
        rparams["itypes"] = itypes
      end
      if params["latitude"] != nil && params["longitude"] != nil then
        rparams["latlng"] = "#{params["latitude"]},#{params["longitude"]}"
      end
      if params["startT"] != nil then
        rparams["startT"] = ((params["startT"].to_r) * 1000).round(0).to_s
      end
      if params["endT"] != nil then
        rparams["endT"] = ((params["endT"].to_r) * 1000).round(0).to_s
      end

      @http.apost(PredictionIO::AsyncRequest.new(versioned_path("/items.#{@apiformat}"), rparams))
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
      if iid_or_res.is_a?(PredictionIO::AsyncResponse) then
        response = iid_or_res.get
      else
        response = acreate_item(*args).get
      end
      unless response.is_a?(Net::HTTPCreated) then
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
      @http.aget(PredictionIO::AsyncRequest.new(versioned_path("/items/#{iid}.#{@apiformat}"),
                                           "appkey" => @appkey,
                                           "iid" => iid))
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
      if iid_or_res.is_a?(PredictionIO::AsyncResponse) then
        response = iid_or_res.get
      else
        response = aget_item(iid_or_res).get
      end
      if response.is_a?(Net::HTTPOK) then
        res = JSON.parse(response.body)
        ct = Rational(res["ct"], 1000)
        res["ct"] = Time.at(ct)
        if res["latlng"] != nil then
          latlng = res["latlng"]
          res["latitude"] = latlng[0]
          res["longitude"] = latlng[1]
        end
        if res["startT"] != nil then
          startT = Rational(res["startT"], 1000)
          res["startT"] = Time.at(startT)
        end
        if res["endT"] != nil then
          endT = Rational(res["endT"], 1000)
          res["endT"] = Time.at(endT)
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
      @http.adelete(PredictionIO::AsyncRequest.new(versioned_path("/items/#{iid}.#{@apiformat}"),
                                               "appkey" => @appkey,
                                               "iid" => iid))
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
      if iid_or_res.is_a?(PredictionIO::AsyncResponse) then
        response = iid_or_res.get
      else
        response = adelete_item(iid_or_res).get
      end
      unless response.is_a?(Net::HTTPOK) then
        begin
          msg = response.body
        rescue Exception
          raise ItemNotDeletedError, response
        end
        raise ItemNotDeletedError, msg
      end
    end

    # :category: Asynchronous Methods
    # Asynchronously request to get the top n recommendations for a user from an ItemRec engine and return a PredictionIO::AsyncResponse object immediately.
    #
    # Corresponding REST API method: GET /engines/itemrec/:engine/topn
    #
    # See also #get_itemrec_top_n.
    def aget_itemrec_top_n(engine, uid, n, params = {})
      rparams = Hash.new
      rparams["appkey"] = @appkey
      rparams["uid"] = uid
      rparams["n"] = n
      if params["itypes"] != nil &&
          params["itypes"].kind_of?(Array) &&
          params["itypes"].length > 0 then
        rparams["itypes"] = params["itypes"].join(",")
      else
        rparams["itypes"] = params["itypes"]
      end
      if params["latitude"] != nil && params["longitude"] != nil then
        rparams["latlng"] = "#{params["latitude"]},#{params["longitude"]}"
      end
      if params["within"] != nil then
        rparams["within"] = params["within"]
      end
      if params["unit"] != nil then
        rparams["unit"] = params["unit"]
      end
      @http.aget(PredictionIO::AsyncRequest.new(versioned_path("/engines/itemrec/#{engine}/topn.#{@apiformat}"), rparams))
    end

    # :category: Synchronous Methods
    # Synchronously request to get the top n recommendations for a user from an ItemRec engine and block until a response is received.
    #
    # See #aget_itemrec_top_n for a description of special argument handling.
    #
    # call-seq:
    # get_recommendations(uid, n, params = {})
    # get_recommendations(async_response)
    def get_itemrec_top_n(*args)
      uid_or_res = args[0]
      if uid_or_res.is_a?(PredictionIO::AsyncResponse) then
        response = uid_or_res.get
      else
        response = aget_itemrec_top_n(*args).get
      end
      if response.is_a?(Net::HTTPOK) then
        res = JSON.parse(response.body)
        res["iids"]
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
    # Asynchronously request to record a user-rate-item action and return a PredictionIO::AsyncResponse object immediately.
    #
    # Corresponding REST API method: POST /actions/u2i/rate
    #
    # See also #user_rate_item.
    def auser_rate_item(uid, iid, rate, params = {})
      params["rate"] = rate
      auser_action_item("rate", uid, iid, params)
    end

    # :category: Synchronous Methods
    # Synchronously request to record a user-rate-item action and block until a response is received.
    #
    # See #auser_rate_item.
    #
    # call-seq:
    # user_rate_item(uid, iid, rate, params = {})
    # user_rate_item(async_response)
    def user_rate_item(*args)
      if !args[0].is_a?(PredictionIO::AsyncResponse) then
        args.unshift("rate")
        params = args[4]
        if params == nil then
          params = Hash.new
        end
        params["rate"] = args[3]
        args[3] = params
      end
      user_action_item(*args)
    end

    # :category: Asynchronous Methods
    # Asynchronously request to record a user-like-item action and return a PredictionIO::AsyncResponse object immediately.
    #
    # Corresponding REST API method: POST /actions/u2i/like
    #
    # See also #user_like_item.
    def auser_like_item(uid, iid, params = {})
      auser_action_item("like", uid, iid, params)
    end

    # :category: Synchronous Methods
    # Synchronously request to record a user-like-item action and block until a response is received.
    #
    # See also #auser_like_item.
    #
    # call-seq:
    # user_like_item(uid, iid, params = {})
    # user_like_item(async_response)
    def user_like_item(*args)
      if !args[0].is_a?(PredictionIO::AsyncResponse) then
        args.unshift("like")
      end
      user_action_item(*args)
    end

    # :category: Asynchronous Methods
    # Asynchronously request to record a user-dislike-item action and return a PredictionIO::AsyncResponse object immediately.
    #
    # Corresponding REST API method: POST /actions/u2i/dislike
    #
    # See also #user_dislike_item.
    def auser_dislike_item(uid, iid, params = {})
      auser_action_item("dislike", uid, iid, params)
    end

    # :category: Synchronous Methods
    # Synchronously request to record a user-dislike-item action and block until a response is received.
    #
    # See also #auser_dislike_item.
    #
    # call-seq:
    # user_dislike_item(uid, iid, params = {})
    # user_dislike_item(async_response)
    def user_dislike_item(*args)
      if !args[0].is_a?(PredictionIO::AsyncResponse) then
        args.unshift("dislike")
      end
      user_action_item(*args)
    end

    # :category: Asynchronous Methods
    # Asynchronously request to record a user-view-item action and return a PredictionIO::AsyncResponse object immediately.
    #
    # Corresponding REST API method: POST /actions/u2i/view
    #
    # See also #user_view_item.
    def auser_view_item(uid, iid, params = {})
      auser_action_item("view", uid, iid, params)
    end

    # :category: Synchronous Methods
    # Synchronously request to record a user-view-item action and block until a response is received.
    #
    # See also #auser_view_item.
    #
    # call-seq:
    # user_view_item(uid, iid, params = {})
    # user_view_item(async_response)
    def user_view_item(*args)
      if !args[0].is_a?(PredictionIO::AsyncResponse) then
        args.unshift("view")
      end
      user_action_item(*args)
    end

    # :category: Asynchronous Methods
    # Asynchronously request to record a user-conversion-item action and return a PredictionIO::AsyncResponse object immediately.
    #
    # Corresponding REST API method: POST /actions/u2i/conversion
    #
    # See also #user_conversion_item.
    def auser_conversion_item(uid, iid, params = {})
      auser_action_item("conversion", uid, iid, params)
    end

    # :category: Synchronous Methods
    # Synchronously request to record a user-conversion-item action and block until a response is received.
    #
    # See also #auser_conversion_item.
    #
    # call-seq:
    # user_conversion_item(uid, iid, params = {})
    # user_conversion_item(async_response)
    def user_conversion_item(*args)
      if !args[0].is_a?(PredictionIO::AsyncResponse) then
        args.unshift("conversion")
      end
      user_action_item(*args)
    end

    # :nodoc: all
    private

    def versioned_path(path)
      # disabled for now
      # "/#{@apiversion}#{path}"
      path
    end

    def auser_action_item(action, uid, iid, params = {})
      rparams = params
      rparams["appkey"] = @appkey
      rparams["uid"] = uid
      rparams["iid"] = iid
      if params["t"] != nil then
        rparams["t"] = ((params["t"].to_r) * 1000).round(0).to_s
      end
      if params["latitude"] != nil && params["longitude"] != nil then
        rparams["latlng"] = "#{params["latitude"]},#{params["longitude"]}"
      end
      @http.apost(PredictionIO::AsyncRequest.new(versioned_path("/actions/u2i/#{action}.#{@apiformat}"), rparams))
    end

    def user_action_item(*args)
      action_or_res = args[0]
      if action_or_res.is_a?(PredictionIO::AsyncResponse) then
        response = action_or_res.get
      else
        response = auser_action_item(*args).get
      end
      unless response.is_a?(Net::HTTPCreated) then
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
