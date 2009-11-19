require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Dropbox do
  describe ".api_url" do
    before :each do
      @prefix = "#{Dropbox::HOST}/#{Dropbox::VERSION}/"
    end
    it "should use the HOST and VERSION" do
      Dropbox.api_url.should eql(@prefix)
    end

    it "should concatenate path elements with slashes" do
      Dropbox.api_url("foo", :bar, 123).should eql(@prefix + "foo/bar/123")
    end

    it "should use the trailing hash as query params" do
      [ @prefix + "foo/bar?string=val&hash=123", @prefix + "foo/bar?hash=123&string=val" ].should include(Dropbox.api_url("foo", :bar, 'string' => 'val', :hash => 123))
    end

    it "should CGI-escape path elements and query parameters" do
      Dropbox.api_url("foo space", "amp&ersand" => 'eq=uals').should eql(@prefix + "foo%20space?amp%26ersand=eq%3Duals")
    end
  end

  describe ".check_path" do
    it "should raise an exception if the path contains a backslash" do
      lambda { Dropbox.check_path "hello\\there" }.should raise_error(ArgumentError)
    end

    it "should raise an exception if the path is longer than 256 characters" do
      lambda { Dropbox.check_path "a"*257 }.should raise_error(ArgumentError)
    end

    it "should otherwise return the path unchanged" do
      path = "valid path/here"
      lambda { Dropbox.check_path(path).should eql(path) }.should_not raise_error
    end
  end
end
