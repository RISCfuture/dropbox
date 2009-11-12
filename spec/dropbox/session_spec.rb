require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Dropbox::Session do
  describe ".new" do
    it "should create a new OAuth::Consumer" do
      key = 'test_key'
      secret = 'test_secret'
      options_hash = [ 'request_token', 'authorize', 'access_token' ].inject({}) { |hsh, cur| hsh["#{cur}_path".to_sym] = "/#{Dropbox::VERSION}/oauth/#{cur}" ; hsh }
      options_hash[:site] = Dropbox::HOST

      consumer_mock = mock('OAuth::Consumer')
      consumer_mock.stub!(:get_request_token)
      OAuth::Consumer.should_receive(:new).once.with(key, secret, options_hash).and_return(consumer_mock)

      Dropbox::Session.new(key, secret)
    end

    it "should get the request token" do
      consumer_mock = mock('OAuth::Consumer')
      consumer_mock.should_receive(:get_request_token).once
      OAuth::Consumer.stub!(:new).and_return(consumer_mock)

      Dropbox::Session.new('foo', 'bar')
    end
  end

  describe "#authorize_url" do
    before :each do
      consumer_mock = mock("OAuth::Consumer")
      @token_mock = mock("OAuth::RequestToken")
      consumer_mock.stub!(:get_request_token).and_return(@token_mock)
      OAuth::Consumer.stub!(:new).and_return(consumer_mock)
      @session = Dropbox::Session.new('foo', 'bar')
    end

    it "should raise an error if the session is already authorized" do
      @session.stub!(:authorized?).and_return(true)

      lambda { @session.authorize_url }.should raise_error(Dropbox::AlreadyAuthorizedError)
    end

    it "should call authorize_url on the request token" do
      @token_mock.should_receive(:authorize_url).once
      @session.authorize_url
    end

    it "should pass all parameters to the request token" do
      @token_mock.should_receive(:authorize_url).once.with(:a, 'b', :c => 123)
      @session.authorize_url(:a, 'b', :c => 123)
    end
  end

  describe "#authorize" do
    before :each do
      consumer_mock = mock("OAuth::Consumer")
      @token_mock = mock("OAuth::RequestToken")
      consumer_mock.stub!(:get_request_token).and_return(@token_mock)
      OAuth::Consumer.stub!(:new).and_return(consumer_mock)
      @session = Dropbox::Session.new('foo', 'bar')
    end

    it "should call get_access_token on the request_token and pass the given options" do
      options = { :foo => 'bar' }
      @token_mock.should_receive(:get_access_token).once.with(options)
      @session.authorize(options)
    end

    it "should make authorized? return true if an access token is returned" do
      @token_mock.stub!(:get_access_token).and_return(Object.new)
      @session.authorize({ 'foo' => 'bar' })
      @session.should be_authorized
    end

    it "should make authorized? return false if no access token is returned" do
      @token_mock.stub!(:get_access_token).and_return(nil)
      @session.authorize({ 'foo' => 'bar' })
      @session.should_not be_authorized
    end

    it "should return true if authorized" do
      @token_mock.stub!(:get_access_token).and_return(Object.new)
      @session.authorize({ 'foo' => 'bar' }).should be_true
    end

    it "should return false if unauthorized" do
      @token_mock.stub!(:get_access_token).and_return(nil)
      @session.authorize({ 'foo' => 'bar' }).should be_false
    end
  end

  describe "#authorized?" do
    #TODO this method remains opaque for purposes of testing
  end

  describe "#serialize" do
    before :each do
      @consumer_mock = mock("OAuth::Consumer")
      @token_mock = mock("OAuth::RequestToken")
      @consumer_mock.stub!(:get_request_token).and_return(@token_mock)
      OAuth::Consumer.stub!(:new).and_return(@consumer_mock)
      @session = Dropbox::Session.new('foo', 'bar')
    end

    it "should return the consumer key and secret and the request token and secret in YAML form if unauthorized" do
      @consumer_mock.stub!(:key).and_return("consumer key")
      @consumer_mock.stub!(:secret).and_return("consumer secret")
      @token_mock.stub!(:token).and_return("request token")
      @token_mock.stub!(:secret).and_return("request token secret")

      @session.serialize.should eql([ "consumer key", "consumer secret", false, "request token", "request token secret" ].to_yaml)
    end

    it "should return the consumer key and secret and the access token and secret in YAML form if authorized" do
      pending "access token is opaque"
    end
  end

  describe ".deserialize" do
    it "should raise an error if an improper YAML is provided" do
      lambda { Dropbox::Session.deserialize([ 1, 2, 3].to_yaml) }.should raise_error(ArgumentError)
    end

    it "should return a properly initialized unauthorized instance" do
      mock_session = mock('Dropbox::Session')
      Dropbox::Session.should_receive(:new).once.with('key', 'secret').and_return(mock_session)
      
      Dropbox::Session.deserialize([ 'key', 'secret', false, 'a', 'b' ].to_yaml).should eql(mock_session)
      #TODO request token remains opaque for purposes of testing
    end

    it "should return a properly initialized authorized instance" do
      pending "access token remains opaque for purposes of testing"
    end
  end
end
