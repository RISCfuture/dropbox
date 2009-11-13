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

def stub_for_upload_testing
  @consumer_mock.stub!(:key).and_return("consumer key")
  @consumer_mock.stub!(:secret).and_return("consumer secret")
  @consumer_mock.stub!(:sign!).and_return { |req, _| req.stub!(:to_hash).and_return('authorization' => ["Oauth", "test"]) }

  @token_mock.stub!(:token).and_return("access token")
  @token_mock.stub!(:secret).and_return("access secret")

  @response.stub!(:kind_of?).with(Net::HTTPSuccess).and_return(true)
  @response.stub!(:body).and_return('{"test":"val"}')

  Net::HTTP.stub!(:start).and_return(@response)
end

def response_acts_as(subclass)
  @response.stub(:kind_of?).and_return(false)
  @response.stub(:kind_of?).with(subclass).and_return(true) if subclass
end

describe Dropbox::API do
  before :each do
    @consumer_mock = mock("OAuth::Consumer")
    token_mock = mock("OAuth::RequestToken")
    @token_mock = mock("OAuth::AccessToken")
    token_mock.stub!(:get_access_token).and_return(@token_mock)
    @consumer_mock.stub!(:get_request_token).and_return(token_mock)
    OAuth::Consumer.stub!(:new).and_return(@consumer_mock)

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
      response_acts_as Net::HTTPNotFound
      @token_mock.stub!(:post).and_return(@response)

      lambda { @session.copy('a', 'b') }.should raise_error(Dropbox::FileNotFoundError)
    end

    it "should re-raise 403's as FileExistsErrors" do
      response_acts_as Net::HTTPForbidden
      @token_mock.stub!(:post).and_return(@response)

      lambda { @session.copy('a', 'b') }.should raise_error(Dropbox::FileExistsError)
    end

    it "should raise other errors unmodified" do
      @response.stub(:kind_of?).and_return(false)
      @token_mock.stub!(:post).and_return(@response)

      lambda { @session.copy('a', 'b') }.should raise_error(Dropbox::UnsuccessfulResponseError)
    end
  end

  describe "#move" do
    before :each do
      @response.stub!(:body).and_return('{"a":"b"}')
    end

    it "should call the fileops/move API method" do
      should_receive_api_method_with_arguments @token_mock, :post, 'fileops/move', { :from_path => 'source%2Ffile', :to_path => 'dest%2Ffile', :root => 'dropbox' }, @response
      @session.move 'source/file', 'dest/file'
    end

    it "should return the metadata as a struct" do
      @response.stub!(:body).and_return( { :foo => :bar, :baz => { :hey => :you } }.to_json)
      @token_mock.stub!(:post).and_return(@response)

      result = @session.move('a', 'b')
      result.foo.should eql('bar')
      result.baz.hey.should eql('you')
    end

    it "should strip a leading slash from source" do
      should_receive_api_method_with_arguments @token_mock, :post, 'fileops/move', { :from_path => 'source%2Ffile', :to_path => 'dest%2Ffile', :root => 'dropbox' }, @response
      @session.move '/source/file', 'dest/file'
    end

    it "should strip a leading slash from target" do
      should_receive_api_method_with_arguments @token_mock, :post, 'fileops/move', { :from_path => 'source%2Ffile', :to_path => 'dest%2Ffile', :root => 'dropbox' }, @response
      @session.move 'source/file', '/dest/file'
    end

    it "should set the target file name to the source file name if the target is a directory path" do
      should_receive_api_method_with_arguments @token_mock, :post, 'fileops/move', { :from_path => 'source%2Ffile', :to_path => 'dest%2Ffile', :root => 'dropbox' }, @response
      @session.move 'source/file', 'dest/'
    end

    it "should re-raise 404's as FileNotFoundErrors" do
      response_acts_as Net::HTTPNotFound
      @token_mock.stub!(:post).and_return(@response)

      lambda { @session.move('a', 'b') }.should raise_error(Dropbox::FileNotFoundError)
    end

    it "should re-raise 403's as FileExistsErrors" do
      response_acts_as Net::HTTPForbidden
      @token_mock.stub!(:post).and_return(@response)

      lambda { @session.move('a', 'b') }.should raise_error(Dropbox::FileExistsError)
    end

    it "should raise other errors unmodified" do
      response_acts_as nil
      @token_mock.stub!(:post).and_return(@response)

      lambda { @session.move('a', 'b') }.should raise_error(Dropbox::UnsuccessfulResponseError)
    end
  end

  describe "#rename" do
    it "should raise an error if the new name has a slash in it" do
      lambda { @session.rename 'file', 'new/name' }.should raise_error(ArgumentError)
    end

    it "should call move with the appropriate path and return the result of the call" do
      @session.should_receive(:move).once.with('old/path/to/file', 'old/path/to/new_file', :sandbox => true).and_return(@response)
      @session.rename('old/path/to/file', 'new_file', :sandbox => true).should eql(@response)
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
      response_acts_as Net::HTTPForbidden
      @token_mock.stub!(:post).and_return(@response)

      lambda { @session.create_folder('a') }.should raise_error(Dropbox::FileExistsError)
    end

    it "should raise other errors unmodified" do
      response_acts_as nil
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
      response_acts_as Net::HTTPNotFound
      @token_mock.stub!(:post).and_return(@response)

      lambda { @session.delete('a') }.should raise_error(Dropbox::FileNotFoundError)
    end
    
    it "should raise other errors unmodified" do
      response_acts_as nil
      @token_mock.stub!(:post).and_return(@response)

      lambda { @session.delete('a') }.should raise_error(Dropbox::UnsuccessfulResponseError)
    end
  end

  describe "#link" do
    before :each do
      @response.stub!(:code).and_return(304)
      response_acts_as Net::HTTPFound
      @response.stub!(:[]).and_return("new location")
    end

    it "should call the API method links" do
      should_receive_api_method_with_arguments @token_mock, :get, 'links', {}, @response, 'some/file', 'dropbox'
      @session.link 'some/file'
    end

    it "should strip a leading slash" do
      should_receive_api_method_with_arguments @token_mock, :get, 'links', {}, @response, 'some/file', 'dropbox'
      @session.link '/some/file'
    end

    it "should rescue 304's and return the Location header" do
      should_receive_api_method_with_arguments @token_mock, :get, 'links', {}, @response, 'some/file', 'dropbox'
      lambda { @session.link('some/file').should eql("new location") }.should_not raise_error
    end

    it "should re-raise other errors unmodified" do
      response_acts_as nil
      @token_mock.stub!(:get).and_return(@response)
      lambda { @session.link('a') }.should raise_error(Dropbox::UnsuccessfulResponseError)
    end
  end

  describe "#metadata" do
    before :each do
      @response.stub!(:body).and_return('{"a":"b"}')
    end

    it "should call the API method metadata" do
      should_receive_api_method_with_arguments @token_mock, :get, 'metadata', { :list => 'true' }, @response, 'some/file', 'dropbox'
      @session.metadata 'some/file'
    end

    it "should strip a leading slash" do
      should_receive_api_method_with_arguments @token_mock, :get, 'metadata', { :list => 'true' }, @response, 'some/file', 'dropbox'
      @session.metadata '/some/file'
    end

    it "should set file_limit if :limit is set" do
      should_receive_api_method_with_arguments @token_mock, :get, 'metadata', { :list => 'true', :file_limit => '123' }, @response, 'some/file', 'dropbox'
      @session.metadata 'some/file', :limit => 123
    end

    it "should set list=false if :suppress_list is set" do
      should_receive_api_method_with_arguments @token_mock, :get, 'metadata', { :list => 'false' }, @response, 'some/file', 'dropbox'
      @session.metadata 'some/file', :suppress_list => true
    end

    it "should rescue 406's and re-raise them as TooManyEntriesErrors" do
      response_acts_as Net::HTTPNotAcceptable
      @token_mock.stub!(:get).and_return(@response)
      
      lambda { @session.metadata('a') }.should raise_error(Dropbox::TooManyEntriesError)
    end

    it "should rescue 404's and re-raise them as FileNotFoundErrors" do
      response_acts_as Net::HTTPNotFound
      @token_mock.stub!(:get).and_return(@response)

      lambda { @session.metadata('a') }.should raise_error(Dropbox::FileNotFoundError)
    end

    it "should re-raise other errors unmodified" do
      response_acts_as nil
      @token_mock.stub!(:get).and_return(@response)

      lambda { @session.metadata('a') }.should raise_error(Dropbox::UnsuccessfulResponseError)
    end
  end

  describe "#list" do
    before :each do
      @response = mock('metadata')
    end

    it "should call the metadata method and return the contents attribute" do
      @response.should_receive(:contents).once.and_return([ 'contents' ])
      @session.should_receive(:metadata).once.with('my/file', an_instance_of(Hash)).and_return(@response)

      @session.list('my/file').should == [ 'contents' ]
    end

    it "should not allow suppress_list to be set to true" do
      @response.stub!(:contents)
      @session.should_receive(:metadata).once.with('my/file', hash_including(:hash => true, :suppress_list => false)).and_return(@response)

      @session.list('my/file', :suppress_list => true, :hash => true)
    end
  end

  describe "#upload" do
    before :each do
      stub_for_upload_testing
    end

    describe "parameters" do
      describe "given a File object" do
        before :each do
          @file = File.open(__FILE__)
        end

        after :each do
          @file.close
        end

        it "should use the File object as the stream" do
          UploadIO.should_receive(:convert!).once.with(@file, anything, File.basename(__FILE__), __FILE__)
          @session.upload @file, 'remote/'
        end
      end

      describe "given a String object" do
        before :each do
          @string = __FILE__
          @file = File.new(__FILE__)
          File.should_receive(:new).once.with(@string).and_return(@file)
        end

        it "should use the file at that path as the stream" do
          UploadIO.should_receive(:convert!).once.with(@file, anything, File.basename(__FILE__), __FILE__)
          @session.upload @string, 'remote/'
        end
      end

      it "should raise an error if given an unknown argument type" do
        lambda { @session.upload 123, 'path' }.should raise_error(ArgumentError)
      end
    end

    describe "request" do
      before :each do
        @request = mock('Net::HTTPRequest')
        @request.stub!(:[]=)
      end

      it "should strip a leading slash from the remote path" do
        Net::HTTP::Post::Multipart.should_receive(:new).once do |*args|
          args.first.should eql("/#{Dropbox::VERSION}/files/dropbox/path")
          @request
        end

        @session.upload __FILE__, '/path'
      end

      it "should call the files API method" do
        Net::HTTP::Post::Multipart.should_receive(:new).once do |*args|
          args.first.should eql("/#{Dropbox::VERSION}/files/dropbox/path/to/file")
          @request
        end

        @session.upload __FILE__, 'path/to/file'
      end

      it "should use the sandbox root if specified" do
        Net::HTTP::Post::Multipart.should_receive(:new).once do |*args|
          args.first.should eql("/#{Dropbox::VERSION}/files/sandbox/path/to/file")
          @request
        end

        @session.upload __FILE__, 'path/to/file', :sandbox => true
      end

      it "should set the authorization content header to the signed OAuth request" do
        Net::HTTP::Post::Multipart.stub!(:new).and_return(@request)
        @request.should_receive(:[]=).once.with('authorization', 'Oauth, test')

        @session.upload __FILE__, 'blah'
      end

      it "should create a multipart POST request with the 'file' parameter set to the file of type application/octet-stream" do
        Net::HTTP::Post::Multipart.should_receive(:new).once.with("/#{Dropbox::VERSION}/files/dropbox/hello", hash_including('file' => an_instance_of(File))).and_return(@request)

        @session.upload __FILE__, 'hello'
      end

      it "should send the request" do
        uri = URI.parse(Dropbox::ALTERNATE_HOSTS['files'])
        Net::HTTP.should_receive(:start).once.with(uri.host, uri.port).and_return(@response)

        @session.upload __FILE__, 'test'
      end
    end
  end

  {
          :account => [ :get ],
          :upload => [ :post, __FILE__, 'path/here' ],
          :copy => [ :post, 'source/file', 'dest/file' ],
          :move => [ :post, 'source/file', 'dest/file' ],
          :create_folder => [ :post, 'new/folder' ],
          :metadata => [ :get, 'some/file' ]
  }.each do |meth, args|
    describe meth do
      before :each do
        stub_for_upload_testing
        @token_mock.stub!(args.first).and_return(@response)
      end

      it "should parse the JSON response if successful" do
        @response.stub!(:body).and_return('{"test":"json"}')
        @session.send(meth, *(args[1..-1]))
      end

      it "should raise a ParseError if the JSON is invalid" do
        @response.stub!(:body).and_return('sdgsdg')
        lambda { @session.send(meth, *(args[1..-1])) }.should raise_error(Dropbox::ParseError)
      end

      it "should raise UnsuccessfulResponseError if unsuccessful" do
        @response.stub!(:kind_of?).and_return(false)
        lambda { @session.send(meth, *(args[1..-1])) }.should raise_error(Dropbox::UnsuccessfulResponseError)
      end
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
          :move => [ :post, 'source/file', 'dest/file' ],
          :create_folder => [ :post, 'new/folder' ],
          :delete => [ :post, 'some/file' ],
          :link => [ :get, 'some/file' ],
          :metadata => [ :get, 'some/file' ]
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
