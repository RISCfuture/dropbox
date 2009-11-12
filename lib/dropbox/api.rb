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
  #
  # == Sandboxing
  #
  # The Dropbox API includes a feature called "Sandboxing" whereby all
  # operations on files are limited to a sandbox folder within the user's
  # Dropbox. If your credentials allow you sandbox access only, you should set
  # the +sandbox+ attribute:
  #
  #  session.sandbox = true
  #
  # After setting this attribute, file manipulation will be performed within the
  # sandbox environment.
  #
  # Most file-related operations take options that allow you to temporarily
  # revert into our out of sandbox mode, regardless of the value of the
  # +sandbox+ attribute.

  module API
    include Dropbox::Memoization

    # Returns a Struct with information about the user's account. See
    # http://developers.dropbox.com/python/base.html#account-info for more
    # information on the data returned.

    def account
      get('account', 'info').to_struct_recursively
    end
    memoize :account

    # Downloads the file at the given path relative to the Dropbox root. If
    # the +sandbox+ attribute is set to true, takes the path to be relative to
    # the sandbox root.
    #
    # Returns the contents of the downloaded file as a String. Support for
    # streaming downloads and range queries is available server-side, but not
    # available in this API client due to limitations of the OAuth gem.
    #
    # Options:
    #
    # +sandbox+:: If true, and not in sandbox mode, temporarily uses sandbox
    #             mode.
    # +dropbox+:: If true, and in sandbox mode, temporarily leaves sandbox mode.

    def download(path, options={})
      path.sub! /^\//, ''
      api_body :get, 'files', root(options), *(path.split('/'))
      #TODO streaming, range queries
    end

    # Copies the +source+ file to the path at +target+. If +target+ ends with a
    # slash, the new file will share the same name as the old file. Returns a
    # Struct with metadata for the new file. (See the info method.)
    #
    # Both paths are assumed to be relative to the Dropbox root, or if sandbox
    # is enabled, the sandbox root.
    #
    # Raises FileNotFoundError if +source+ does not exist. Raises
    # FileExistsError if +target+ already exists.
    #
    # Options:
    #
    # +sandbox+:: If true, and not in sandbox mode, temporarily uses sandbox
    #             mode.
    # +dropbox+:: If true, and in sandbox mode, temporarily leaves sandbox mode.
    #
    #TODO The API documentation says this method returns 404/403 if the source or target is invalid, but it actually returns 5xx.


    def copy(source, target, options={})
      source.sub! /^\//, ''
      target.sub! /^\//, ''
      target << File.basename(source) if target.ends_with?('/')
      begin
        parse_metadata(post('fileops', 'copy', :from_path => source, :to_path => target, :root => root(options))).to_struct_recursively
      rescue UnsuccessfulResponseError => error
        raise FileNotFoundError.new(source) if error.response.kind_of?(Net::HTTPNotFound)
        raise FileExistsError.new(target) if error.response.kind_of?(Net::HTTPForbidden)
        raise error
      end
    end
    alias :cp :copy

    # Creates a folder at the given path. The path is assumed to be relative to
    # the Dropbox root, or if sandbox is enabled, the sandbox root.
    #
    # Raises FileExistsError if there is already a file or folder at +path+.
    #
    # Options:
    #
    # +sandbox+:: If true, and not in sandbox mode, temporarily uses sandbox
    #             mode.
    # +dropbox+:: If true, and in sandbox mode, temporarily leaves sandbox mode.
    #
    #TODO The API documentation says this method returns 403 if the path already exists, but it actually appends " (1)" to the end of the name and returns 200.

    def create_folder(path, options={})
      path.sub! /^\//, ''
      path.sub! /\/$/, ''
      begin
        parse_metadata(post('fileops', 'create_folder', :path => path, :root => root(options))).to_struct_recursively
      rescue UnsuccessfulResponseError => error
        raise FileExistsError.new(path) if error.response.kind_of?(Net::HTTPForbidden)
        raise error
      end
    end
    alias :mkdir :create_folder

    # Deletes a file or folder at the given path. The path is assumed to be
    # relative to the Dropbox root, or if sandbox is enabled, the sandbox root.
    #
    # Raises FileNotFoundError if the file or folder does not exist at +path+.
    #
    # Options:
    #
    # +sandbox+:: If true, and not in sandbox mode, temporarily uses sandbox
    #             mode.
    # +dropbox+:: If true, and in sandbox mode, temporarily leaves sandbox mode.
    #
    #TODO The API documentation says this method returns 404 if the path does not exist, but it actually fails silently.
    
    def delete(path, options={})
      path.sub! /^\//, ''
      path.sub! /\/$/, ''
      begin
        api_response(:post, 'fileops', 'delete', :path => path, :root => root(options))
      rescue UnsuccessfulResponseError => error
        raise FileNotFoundError.new(path) if error.response.kind_of?(Net::HTTPNotFound)
        raise error
      end
      return true
    end
    alias :rm :delete

    # Moves the +source+ file to the path at +target+. If +target+ ends with a
    # slash, the file name will remain unchanged. If +source+ and +target+ share
    # the same path but have differing file names, the file will be renamed (see
    # also the rename method). Returns a Struct with metadata for the new file.
    # (See the info method.)
    #
    # Both paths are assumed to be relative to the Dropbox root, or if sandbox
    # is enabled, the sandbox root.
    #
    # Raises FileNotFoundError if +source+ does not exist. Raises
    # FileExistsError if +target+ already exists.
    #
    # Options:
    #
    # +sandbox+:: If true, and not in sandbox mode, temporarily uses sandbox
    #             mode.
    # +dropbox+:: If true, and in sandbox mode, temporarily leaves sandbox mode.
    #
    #TODO The API documentation says this method returns 404/403 if the source or target is invalid, but it actually returns 5xx.


    def move(source, target, options={})
      source.sub! /^\//, ''
      target.sub! /^\//, ''
      target << File.basename(source) if target.ends_with?('/')
      begin
        parse_metadata(post('fileops', 'move', :from_path => source, :to_path => target, :root => root(options))).to_struct_recursively
      rescue UnsuccessfulResponseError => error
        raise FileNotFoundError.new(source) if error.response.kind_of?(Net::HTTPNotFound)
        raise FileExistsError.new(target) if error.response.kind_of?(Net::HTTPForbidden)
        raise error
      end
    end
    alias :mv :move

    # Renames a file. Takes the same options and raises the same exceptions as
    # the move method.
    #
    # Calling
    #
    #  session.rename 'path/to/file', 'new_name'
    #
    # is equivalent to calling
    #
    #  session.move 'path/to/file', 'path/to/new_name'

    def rename(path, new_name, options={})
      raise ArgumentError, "Names cannot have slashes in them" if new_name.include?('/')
      path.sub! /\/$/, ''
      destination = path.split('/')
      destination[destination.size - 1] = new_name
      destination = destination.join('/')
      move path, destination, options
    end

    # Returns a cookie-protected URL that the authorized user can use to view
    # the file at the given path. This URL requires an authorized user.
    #
    # The path is assumed to be relative to the Dropbox root, or if sandbox is
    # enabled, the sandbox root.
    #
    # Options:
    #
    # +sandbox+:: If true, and not in sandbox mode, temporarily uses sandbox
    #             mode.
    # +dropbox+:: If true, and in sandbox mode, temporarily leaves sandbox mode.

    def link(path, options={})
      path.sub! /^\//, ''
      begin
        api_response(:get, 'links', root(options), *(path.split('/')))
      rescue UnsuccessfulResponseError => error
        return error.response['Location'] if error.response.kind_of?(Net::HTTPFound)
        #TODO shouldn't be using rescue blocks for normal program flow
        raise error
      end
    end
    memoize :link

    # Returns true if this session is in sandboxed mode.

    def sandbox?
      @sandbox.to_bool
    end

    # Turns on or off sandboxed mode.

    def sandbox=(val)
      @sandbox = val.to_bool
    end

    private

    def parse_metadata(hsh)
      hsh[:modified] = Time.parse(hsh[:modified]) if hsh[:modified]
      hsh
    end

    def root(options={})
      if sandbox? then
        return options[:dropbox] ? 'dropbox' : 'sandbox'
      else
        return options[:sandbox] ? 'sandbox' : 'dropbox'
      end
    end

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

  # Superclass of errors relating to Dropbox files.

  class FileError < StandardError
    # The path of the offending file.
    attr_reader :path

    def initialize(path) # :nodoc:
      @path = path
    end

    def message # :nodoc:
      "#{self.class.to_s}: #{@path}"
    end
    alias :to_s :message
    alias :to_str :message
  end

  # Raised when a Dropbox file doesn't exist.

  class FileNotFoundError < FileError; end

  # Raised when a Dropbox file is in the way.

  class FileExistsError < FileError; end
end
