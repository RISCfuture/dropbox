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
end
