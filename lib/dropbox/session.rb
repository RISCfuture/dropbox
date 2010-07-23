# Defines the Dropbox::Session class.

require 'oauth'

module Dropbox

  # This class is a portal to the Dropbox API and a façade over the Ruby OAuth
  # gem allowing developers to authenticate their user's Dropbox accounts.
  #
  # == Authenticating a user
  #
  # You start by creating a new instance and providing your OAuth consumer key
  # and secret. You then call the authorize_url method on your new instance to
  # receive the authorization URL.
  #
  # Once your user visits the URL, it will complete the authorization process on
  # the server side. You should call the authorize method:
  #
  #  session = Dropbox::Session.new(my_key, my_secret)
  #  puts "Now visit #{session.authorize_url}. Hit enter when you have completed authorization."
  #  gets
  #  session.authorize
  #
  # The authorize method must be called on the same instance of Dropbox::Session
  # that gave you the URL. If this is unfeasible (for instance, you are doing
  # this in a stateless Rails application), you can serialize the Session for
  # storage (e.g., in your Rails session):
  #
  #  def authorize
  #    if params[:oauth_token] then
  #      dropbox_session = Dropbox::Session.deserialize(session[:dropbox_session])
  #      dropbox_session.authorize(params)
  #      session[:dropbox_session] = dropbox_session.serialize # re-serialize the authenticated session
  #
  #      redirect_to :action => 'upload'
  #    else
  #      dropbox_session = Dropbox::Session.new('your_consumer_key', 'your_consumer_secret')
  #      session[:dropbox_session] = dropbox_session.serialize
  #      redirect_to dropbox_session.authorize_url(:oauth_callback => root_url)
  #    end
  #  end
  #
  # == Working with the API
  #
  # This class includes the methods of the Dropbox::API module. See that module
  # to learn how to continue using the API.

  class Session
    include API

    # Begins the authorization process. Provide the OAuth key and secret of your
    # API account, assigned by Dropbox. This is the first step in the
    # authorization process.
    #
    # Options:
    #
    # +ssl+:: If true, uses SSL to connect to the Dropbox API server.

    def initialize(oauth_key, oauth_secret, options={})
      @ssl = options[:ssl].to_bool
      @consumer = OAuth::Consumer.new(oauth_key, oauth_secret,
                                      :site => (@ssl ? Dropbox::SSL_HOST : Dropbox::HOST),
                                      :request_token_path => "/#{Dropbox::VERSION}/oauth/request_token",
                                      :authorize_path => "/#{Dropbox::VERSION}/oauth/authorize",
                                      :access_token_path => "/#{Dropbox::VERSION}/oauth/access_token")
      @request_token = @consumer.get_request_token
    end

    # Returns a URL that is used to complete the authorization process. Visiting
    # this URL is the second step in the authorization process, after creating
    # the Session instance.

    def authorize_url(*args)
      if authorized? then
        raise AlreadyAuthorizedError, "You have already been authorized; no need to get an authorization URL."
      else
        return @request_token.authorize_url(*args)
      end
    end

    # Authorizes a user from the information returned by Dropbox. This is the
    # third step in the authorization process, after sending the user to the
    # authorize_url.
    #
    # You can pass to this method a hash containing the keys and values of the
    # OAuth parameters returned by Dropbox. An example in Rails:
    #
    #  session.authorize :oauth_verifier => params[:oauth_verifier]
    #
    # Returns a boolean indicating if authentication was successful.

    def authorize(options={})
      @access_token = @request_token.get_access_token(options)
      @request_token = nil if @access_token
      return @access_token.to_bool
    end

    # Returns true if this session has been authorized.

    def authorized?
      @access_token.to_bool
    end

    # Serializes this object into a string that can then be recreated with the
    # Dropbox::Session.deserialize method.

    def serialize
      if authorized? then
        [ @consumer.key, @consumer.secret, authorized?, @access_token.token, @access_token.secret, @ssl ].to_yaml
      else
        [ @consumer.key, @consumer.secret, authorized?, @request_token.token, @request_token.secret, @ssl ].to_yaml
      end
    end
    
    # Deserializes an instance from a string created from the serialize method.
    # Returns the recreated instance.

    def self.deserialize(data)
      consumer_key, consumer_secret, authorized, token, token_secret, ssl = YAML.load(StringIO.new(data))
      raise ArgumentError, "Must provide a properly serialized #{self.to_s} instance" unless [ consumer_key, consumer_secret, token, token_secret ].all? and authorized == true or authorized == false

      session = self.new(consumer_key, consumer_secret, :ssl => ssl)
      if authorized then
        session.instance_variable_set :@access_token, OAuth::AccessToken.new(session.instance_variable_get(:@consumer), token, token_secret)
      else
        session.instance_variable_set :@request_token, OAuth::RequestToken.new(session.instance_variable_get(:@consumer), token, token_secret)
      end
      
      return session
    end

    def inspect # :nodoc:
      "#<#{self.class.to_s} #{@consumer.key} (#{'un' unless authorized?}authorized)>"
    end

    private

    def access_token
      @access_token || raise(UnauthorizedError, "You need to authorize the Dropbox user before you can call API methods")
    end

    def clone_with_host(host)
      session = dup
      consumer = OAuth::Consumer.new(@consumer.key, @consumer.secret, :site => host)
      session.instance_variable_set :@consumer, consumer
      session.instance_variable_set :@access_token, OAuth::AccessToken.new(consumer, @access_token.token, @access_token.secret)
      return session
    end
  end

  # Raised when trying to call Dropbox API methods without yet having completed
  # the OAuth process.

  class UnauthorizedError < StandardError; end

  # Raised when trying to call Dropbox::Session#authorize_url on an already
  # authorized session.

  class AlreadyAuthorizedError < StandardError; end
end
