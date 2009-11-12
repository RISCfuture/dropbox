# Defines the Dropbox::API module.

require "#{File.expand_path File.dirname(__FILE__)}/memoization"
require 'json'

module Dropbox

  # Extensions to the Dropbox::Session class that add core Dropbox API
  # functionality to this class. You must have authenticated your
  # Dropbox::Session instance before you can call any of these methods. (See the
  # Dropbox::Session class documentation for instructions.)
  #
  # API methods generally return Struct objects containing their results, unless
  # otherwise noted. See the Dropbox API documentation at
  # http://developers.dropbox.com for specific information on the schema of each
  # result.
  #
  # You can opt-in to memoization of API method results. See the
  # Dropbox::Memoization class documentation to learn more.

  module API
    include Dropbox::Memoization

    # Returns a Struct with information about the user's account. See
    # http://developers.dropbox.com/python/base.html#account-info for more
    # information on the data returned.

    def account
      get('account', 'info').to_struct_recursively
    end
    memoize :account
    
    private

    def get(*params)
      api_json :get, *params
    end

    def post(*params)
      api_json :post, *params
    end

    def api_internal(method, request)
      raise UnauthorizedError, "Must authorize before you can use API method" unless @access_token
      response = @access_token.send(method, request)
      raise UnsuccessfulResponseError.new(request, response) unless response.kind_of?(Net::HTTPSuccess)
      return response
    end

    def api_json(method, *params)
      request = Dropbox.api_url(*params)
      response = api_internal(method, request)
      begin
        return JSON.parse(response.body).symbolize_keys_recursively
      rescue JSON::ParserError
        raise ParseError.new(request, response)
      end
    end

    def api_body(method, *params)
      api_response(method, *params).body
    end

    def api_response(method, *params)
      api_internal(method, Dropbox.api_url(*params))
    end
  end

  # Superclass for exceptions raised when the server reports an error.

  class APIError < StandardError
    # The request URL.
    attr_reader :request
    # The Net::HTTPResponse returned by the server.
    attr_reader :response

    def initialize(request, response) # :nodoc:
      @request = request
      @response = response
    end

    def message # :nodoc:
      "API error: #{request}"
    end
    alias :to_s :message
    alias :to_str :message
  end

  # Raised when the Dropbox API returns a response that was not understood.

  class ParseError < APIError
    def message # :nodoc:
      "Invalid response received: #{request}"
    end
  end

  # Raised when something other than 200 OK is returned by an API method.

  class UnsuccessfulResponseError < APIError
    def message # :nodoc:
      "HTTP status #{@response.class.to_s} received: #{request}"
    end
  end
end
