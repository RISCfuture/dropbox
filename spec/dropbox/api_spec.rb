require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

def url_args(url)
  return {} unless url.include?('?')
  _, back = url.split('?')
  return {} unless back
  back.split('&').map { |comp| comp.split('=') }.to_hash
end

def should_receive_api_method_with_arguments(object, method, api_method, arguments, response, path=nil, root=nil)
  object.should_receive(method).once do |url|
    front = url.split('?').first
    front.should eql("#{Dropbox::ALTERNATE_HOSTS[api_method] || Dropbox::HOST}/#{Dropbox::VERSION}/#{api_method}#{'/' + root if root}#{'/' + path if path}")

    query_params = url_args(url)
    query_params.each { |key, val| arguments[key.to_sym].should eql(val) }
    arguments.each { |key, _| query_params.should include(key.to_s) }
    response
  end
end

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
      should_receive_api_method_with_arguments @token_mock, :get, 'account/info', {}, @response
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
      should_receive_api_method_with_arguments @token_mock, :get, 'files', {}, @response, 'path/to/file', 'dropbox'
      @session.download "path/to/file"
    end

    it "should strip a leading slash" do
      should_receive_api_method_with_arguments @token_mock, :get, 'files', {}, @response, 'path/to/file', 'dropbox'
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
    
    it "should call the fileops/copy API method" do
      should_receive_api_method_with_arguments @token_mock, :post, 'fileops/copy', { :from_path => 'source%2Ffile', :to_path => 'dest%2Ffile', :root => 'dropbox' }, @response
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
      should_receive_api_method_with_arguments @token_mock, :post, 'fileops/copy', { :from_path => 'source%2Ffile', :to_path => 'dest%2Ffile', :root => 'dropbox' }, @response
      @session.copy '/source/file', 'dest/file'
    end
    
    it "should strip a leading slash from target" do
      should_receive_api_method_with_arguments @token_mock, :post, 'fileops/copy', { :from_path => 'source%2Ffile', :to_path => 'dest%2Ffile', :root => 'dropbox' }, @response
      @session.copy 'source/file', '/dest/file'
    end

    it "should set the target file name to the source file name if the target is a directory path" do
      should_receive_api_method_with_arguments @token_mock, :post, 'fileops/copy', { :from_path => 'source%2Ffile', :to_path => 'dest%2Ffile', :root => 'dropbox' }, @response
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

  describe "#create_folder" do
    before :each do
      @response.stub!(:body).and_return('{"a":"b"}')
    end
    
    it "should call the fileops/create_folder API method" do
      should_receive_api_method_with_arguments @token_mock, :post, 'fileops/create_folder', { :path => 'new%2Ffolder', :root => 'dropbox' }, @response
      @session.create_folder 'new/folder'
    end

    it "should return the metadata as a struct" do
      @response.stub!(:body).and_return( { :foo => :bar, :baz => { :hey => :you } }.to_json)
      @token_mock.stub!(:post).and_return(@response)

      result = @session.create_folder('a')
      result.foo.should eql('bar')
      result.baz.hey.should eql('you')
    end
    
    it "should strip a leading slash from the path" do
      should_receive_api_method_with_arguments @token_mock, :post, 'fileops/create_folder', { :path => 'new%2Ffolder', :root => 'dropbox' }, @response
      @session.create_folder '/new/folder'
    end
    
    it "should strip a trailing slash from the path" do
      should_receive_api_method_with_arguments @token_mock, :post, 'fileops/create_folder', { :path => 'new%2Ffolder', :root => 'dropbox' }, @response
      @session.create_folder 'new/folder/'
    end

    it "should re-raise 403's as FileExistsErrors" do
      @response.stub(:kind_of?).with(Net::HTTPForbidden).and_return(true)
      @response.stub(:kind_of?).with(Net::HTTPSuccess).and_return(false)
      @token_mock.stub!(:post).and_return(@response)

      lambda { @session.create_folder('a') }.should raise_error(Dropbox::FileExistsError)
    end

    it "should raise other errors unmodified" do
      @response.stub(:kind_of?).with(Net::HTTPForbidden).and_return(false)
      @response.stub(:kind_of?).with(Net::HTTPSuccess).and_return(false)
      @token_mock.stub!(:post).and_return(@response)

      lambda { @session.create_folder('a') }.should raise_error(Dropbox::UnsuccessfulResponseError)
    end
  end

  describe "#delete" do
    it "should call the API method fileops/delete" do
      should_receive_api_method_with_arguments @token_mock, :post, 'fileops/delete', { :path => 'some%2Ffile', :root => 'dropbox' }, @response
      @session.delete 'some/file'
    end

    it "should return true" do
      @token_mock.stub!(:post).and_return(@response)
      @session.delete('some/file').should be_true
    end

    it "should strip a leading slash from the path" do
      should_receive_api_method_with_arguments @token_mock, :post, 'fileops/delete', { :path => 'some%2Ffile', :root => 'dropbox' }, @response
      @session.delete '/some/file'
    end

    it "should strip a trailing slash from the path" do
      should_receive_api_method_with_arguments @token_mock, :post, 'fileops/delete', { :path => 'some%2Ffile', :root => 'dropbox' }, @response
      @session.delete 'some/file/'
    end

    it "should re-raise 404's as FileNotFoundErrors" do
      @response.stub(:kind_of?).with(Net::HTTPNotFound).and_return(true)
      @response.stub(:kind_of?).with(Net::HTTPSuccess).and_return(false)
      @token_mock.stub!(:post).and_return(@response)

      lambda { @session.delete('a') }.should raise_error(Dropbox::FileNotFoundError)
    end
    
    it "should raise other errors unmodified" do
      @response.stub(:kind_of?).with(Net::HTTPNotFound).and_return(false)
      @response.stub(:kind_of?).with(Net::HTTPSuccess).and_return(false)
      @token_mock.stub!(:post).and_return(@response)

      lambda { @session.delete('a') }.should raise_error(Dropbox::UnsuccessfulResponseError)
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
          :copy => [ :post, 'source/file', 'dest/file' ],
          :create_folder => [ :post, 'new/folder' ],
          :delete => [ :post, 'some/file' ]
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
