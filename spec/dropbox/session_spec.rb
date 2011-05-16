require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Dropbox::Session do
  describe ".new" do
    it "should create a new OAuth::Consumer" do
      key = 'test_key'
      secret = 'test_secret'
      options_hash = [ 'request_token', 'authorize', 'access_token' ].inject({}) { |hsh, cur| hsh["#{cur}_path".to_sym] = "/#{Dropbox::VERSION}/oauth/#{cur}" ; hsh }
      options_hash[:site] = Dropbox::AUTH_HOST
      options_hash[:proxy] = nil

      consumer_mock = mock('OAuth::Consumer')
      consumer_mock.stub!(:get_request_token)
      OAuth::Consumer.should_receive(:new).once.with(key, secret, options_hash).and_return(consumer_mock)

      Dropbox::Session.new(key, secret)
    end

    it "should use the SSL host if :ssl => true is given" do
      key = 'test_key'
      secret = 'test_secret'
      options_hash = [ 'request_token', 'authorize', 'access_token' ].inject({}) { |hsh, cur| hsh["#{cur}_path".to_sym] = "/#{Dropbox::VERSION}/oauth/#{cur}" ; hsh }
      options_hash[:site] = Dropbox::AUTH_SSL_HOST
      options_hash[:proxy] = nil

      consumer_mock = mock('OAuth::Consumer')
      consumer_mock.stub!(:get_request_token)
      OAuth::Consumer.should_receive(:new).once.with(key, secret, options_hash).and_return(consumer_mock)

      Dropbox::Session.new(key, secret, :ssl => true)
    end

    it "should create a new OAuth::Consumer" do
      key = 'test_key'
      secret = 'test_secret'
      options_hash = [ 'request_token', 'authorize', 'access_token' ].inject({}) { |hsh, cur| hsh["#{cur}_path".to_sym] = "/#{Dropbox::VERSION}/oauth/#{cur}" ; hsh }
      options_hash[:site] = Dropbox::AUTH_HOST
      options_hash[:proxy] = proxy = mock('proxy')

      consumer_mock = mock('OAuth::Consumer')
      consumer_mock.stub!(:get_request_token)
      OAuth::Consumer.should_receive(:new).once.with(key, secret, options_hash).and_return(consumer_mock)

      Dropbox::Session.new(key, secret, :proxy => proxy)
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

      @session.serialize.should eql([ "consumer key", "consumer secret", false, "request token", "request token secret", false, :sandbox ].to_yaml)
    end

    it "should serialize the SSL setting" do
      @session = Dropbox::Session.new('foo', 'bar', :ssl => true)
      @consumer_mock.stub!(:key).and_return("consumer key")
      @consumer_mock.stub!(:secret).and_return("consumer secret")
      @token_mock.stub!(:token).and_return("request token")
      @token_mock.stub!(:secret).and_return("request token secret")

      @session.serialize.should eql([ "consumer key", "consumer secret", false, "request token", "request token secret", true, :sandbox ].to_yaml)
    end
    
    it "should serialize the mode" do
      @session = Dropbox::Session.new('foo', 'bar')
      @consumer_mock.stub!(:key).and_return("consumer key")
      @consumer_mock.stub!(:secret).and_return("consumer secret")
      @token_mock.stub!(:token).and_return("request token")
      @token_mock.stub!(:secret).and_return("request token secret")
      @session.mode = :dropbox

      @session.serialize.should eql([ "consumer key", "consumer secret", false, "request token", "request token secret", false, :dropbox ].to_yaml)
    end
  end

  describe ".deserialize" do
    before :each do
      @mock_session = mock('Dropbox::Session')
    end

    it "should raise an error if an improper YAML is provided" do
      lambda { Dropbox::Session.deserialize([ 1, 2, 3 ].to_yaml) }.should raise_error(ArgumentError)
    end

    it "should return a properly initialized unauthorized instance" do
      Dropbox::Session.should_receive(:new).once.with('key', 'secret', :ssl => true, :already_authorized => false).and_return(@mock_session)
      @mock_session.should_receive(:mode=).once.with(:dropbox)

      Dropbox::Session.deserialize([ 'key', 'secret', false, 'a', 'b', true, :dropbox ].to_yaml).should eql(@mock_session)
      #TODO request token remains opaque for purposes of testing
    end

    it "should allow the SSL option to be left out" do
      Dropbox::Session.should_receive(:new).once.with('key', 'secret', :ssl => nil, :already_authorized=>false).and_return(@mock_session)
      @mock_session.stub!(:mode=)

      Dropbox::Session.deserialize([ 'key', 'secret', false, 'a', 'b' ].to_yaml).should eql(@mock_session)
    end
    
    it "should allow the mode to be left out" do
      Dropbox::Session.should_receive(:new).once.with('key', 'secret', :ssl => nil, :already_authorized=>false).and_return(@mock_session)
      Dropbox::Session.deserialize([ 'key', 'secret', false, 'a', 'b' ].to_yaml).should eql(@mock_session)
    end
  end

  describe "with Dropbox keys" do
    before(:all) do
      @keys = read_keys_file
    end

    def new_session
      Dropbox::Session.new(@keys['key'], @keys['secret'], :authorizing_user => @keys['email'], :authorizing_password => @keys['password'])
    end

    describe "#authorized?" do
      before(:each) do
        @session = new_session
      end

      it "should be false for sessions that have not been authorized" do
        @session.should_not be_authorized
      end

      it "should be true for sessions that have been authorized" do
        @session.authorize!
        @session.should be_authorized
      end
    end

    describe "#authorize!" do
      describe "with credentials" do
        before(:each) do
          @session = new_session
        end

        it "should not fail" do
          lambda { @session.authorize! }.should_not raise_error
        end

        it "should return the result of #authorize" do
          @session.should_receive(:authorize).and_return("winner!")
          @session.authorize!.should == "winner!"
        end
      end

      describe "with no credentials" do
        it "should fail" do
          @session = Dropbox::Session.new(@keys['key'], @keys['password'])
          lambda { @session.authorize! }.should raise_error
        end
      end
    end

    describe ".deserialize" do
      it "should return a properly initialized authorized instance" do
        @session = new_session
        @session.authorize!.should be_true
        @session_clone = Dropbox::Session.deserialize(@session.serialize)

        @session.serialize.should == @session_clone.serialize
      end
    end

    describe "#serialize" do
      it "should return the consumer key and secret and the access token and secret in YAML form if authorized" do
        @session = new_session
        @session.authorize!.should be_true
        @session.serialize.should eql([ @keys['key'], @keys['secret'], true, @session.send(:access_token).token, @session.send(:access_token).secret, false, :sandbox ].to_yaml)
      end
    end
  end
end
