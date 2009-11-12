require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Dropbox::API do
  before :each do
    consumer_mock = mock("OAuth::Consumer")
    token_mock = mock("OAuth::RequestToken")
    @token_mock = mock("OAuth::AccessToken")
    token_mock.stub!(:get_access_token).and_return(@token_mock)
    consumer_mock.stub!(:get_request_token).and_return(token_mock)
    OAuth::Consumer.stub!(:new).and_return(consumer_mock)

    @session = Dropbox::Session.new('foo', 'bar')
    @session.authorize

    @response = mock('Net::HTTPResponse')
    @response.stub!(:kind_of?).with(Net::HTTPSuccess).and_return(true)
    @response.stub!(:code).and_return(200)
    @response.stub!(:body).and_return("response body")
  end

  describe "#account" do
    it "should call the /account/info API method" do
      @response.stub!(:body).and_return('{"a":"b"}')
      @token_mock.should_receive(:get).once.with("#{Dropbox::HOST}/#{Dropbox::VERSION}/account/info").and_return(@response)
      @session.account
    end

    it "should convert the result into a struct" do
      @response.stub!(:body).and_return( { :foo => :bar, :baz => { :hey => :you } }.to_json)
      @token_mock.stub!(:get).and_return(@response)
      result = @session.account
      result.foo.should eql('bar')
      result.baz.hey.should eql('you')
    end
  end

  describe "#download" do
    it "should call the /files/dropbox API method" do
      @token_mock.should_receive(:get).once.with("#{Dropbox::ALTERNATE_HOSTS['files']}/#{Dropbox::VERSION}/files/dropbox/path/to/file").and_return(@response)
      @session.download "path/to/file"
    end

    it "should strip a leading slash" do
      @token_mock.should_receive(:get).once.with("#{Dropbox::ALTERNATE_HOSTS['files']}/#{Dropbox::VERSION}/files/dropbox/path/to/file").and_return(@response)
      @session.download "/path/to/file"
    end

    it "should return the body of the response" do
      @token_mock.stub!(:get).and_return(@response)
      @session.download("path/to/file").should eql("response body")
    end
  end

  describe "#copy" do
    before :each do
      @response.stub!(:body).and_return('{"a":"b"}')
    end
    
    it "should call the /fileops/copy API method" do
      @token_mock.should_receive(:post).once.with("#{Dropbox::HOST}/#{Dropbox::VERSION}/fileops/copy?root=dropbox&from_path=source%2Ffile&to_path=dest%2Ffile").and_return(@response)
      @session.copy 'source/file', 'dest/file'
    end

    it "should return the metadata as a struct" do
      @response.stub!(:body).and_return( { :foo => :bar, :baz => { :hey => :you } }.to_json)
      @token_mock.stub!(:post).and_return(@response)

      result = @session.copy('a', 'b')
      result.foo.should eql('bar')
      result.baz.hey.should eql('you')
    end

    it "should strip a leading slash from source" do
      @token_mock.should_receive(:post).once.with("#{Dropbox::HOST}/#{Dropbox::VERSION}/fileops/copy?root=dropbox&from_path=source%2Ffile&to_path=dest%2Ffile").and_return(@response)
      @session.copy '/source/file', 'dest/file'
    end
    
    it "should strip a leading slash from target" do
      @token_mock.should_receive(:post).once.with("#{Dropbox::HOST}/#{Dropbox::VERSION}/fileops/copy?root=dropbox&from_path=source%2Ffile&to_path=dest%2Ffile").and_return(@response)
      @session.copy 'source/file', '/dest/file'
    end

    it "should set the target file name to the source file name if the target is a directory path" do
      @token_mock.should_receive(:post).once.with("#{Dropbox::HOST}/#{Dropbox::VERSION}/fileops/copy?root=dropbox&from_path=source%2Ffile&to_path=dest%2Ffile").and_return(@response)
      @session.copy 'source/file', 'dest/'
    end

    it "should re-raise 404's as FileNotFoundErrors" do
      @response.stub(:kind_of?).with(Net::HTTPNotFound).and_return(true)
      @response.stub(:kind_of?).with(Net::HTTPForbidden).and_return(false)
      @response.stub(:kind_of?).with(Net::HTTPSuccess).and_return(false)
      @token_mock.stub!(:post).and_return(@response)

      lambda { @session.copy('a', 'b') }.should raise_error(Dropbox::FileNotFoundError)
    end

    it "should re-raise 403's as FileExistsErrors" do
      @response.stub(:kind_of?).with(Net::HTTPNotFound).and_return(false)
      @response.stub(:kind_of?).with(Net::HTTPForbidden).and_return(true)
      @response.stub(:kind_of?).with(Net::HTTPSuccess).and_return(false)
      @token_mock.stub!(:post).and_return(@response)

      lambda { @session.copy('a', 'b') }.should raise_error(Dropbox::FileExistsError)
    end

    it "should raise other errors unmodified" do
      @response.stub(:kind_of?).and_return(false)
      @token_mock.stub!(:post).and_return(@response)

      lambda { @session.copy('a', 'b') }.should raise_error(Dropbox::UnsuccessfulResponseError)
    end
  end

  describe "#sandbox?" do
    it "should return true if sandboxed" do
      @session.sandbox = true
      @session.should be_sandbox
    end

    it "should return false if not sandboxed" do
      @session.sandbox = false
      @session.should_not be_sandbox
    end
  end

  describe "#sandbox=" do
    it "should enable sandboxing" do
      @session.sandbox = true
      @token_mock.should_receive(:get).once do |url, *rest|
        url.should include('/sandbox')
        url.should_not include('/dropbox')
        @response
      end
      @session.download 'file'
    end

    it "should disable sandboxing" do
      @session.sandbox = false
      @token_mock.should_receive(:get).once do |url, *rest|
        url.should_not include('/sandbox')
        url.should include('/dropbox')
        @response
      end
      @session.download 'file'
    end
  end

  {
          :download => [ :get, 'path/to/file' ],
          :copy => [ :post, 'source/file', 'dest/file' ]
  }.each do |sandbox_method, args|
    describe sandbox_method do
      before :each do
        @response.stub!(:body).and_return('{"a":"b"}')
      end

      it "should use the dropbox root if not sandboxed" do
        @token_mock.should_receive(args.first).once do |url, *rest|
          url.should_not include('sandbox')
          @response
        end
        @session.send(sandbox_method, *(args[1..-1]))
      end

      it "should use the sandbox root if sandboxed" do
        @token_mock.should_receive(args.first).once do |url, *rest|
          url.should include('sandbox')
          @response
        end
        @session.sandbox = true
        @session.send(sandbox_method, *(args[1..-1]))
      end
    end
  end
end
