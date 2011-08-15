require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Dropbox::Entry do
  before :each do
    @session = mock('Dropbox::Session')
    @path = 'test/path/to/file'
    @entry = Dropbox::Entry.new(@session, @path)
    #TODO this constructor is opaque
  end

  describe "#metadata" do
    it "should delegate to the session and return the result" do
      result = mock('result')
      @session.should_receive(:metadata).once.with(@path, {}).and_return(result)

      @entry.metadata.should eql(result)
    end

    it "should pass along options" do
      result = mock('result')
      @session.should_receive(:metadata).once.with(@path, { :sandbox => true }).and_return(result)

      @entry.metadata(:sandbox => true)
    end

    it "should record prior responses and use them automatically" do
      result = mock('result')

      @session.should_receive(:metadata).once.with(@path, {}).and_return(result)
      @entry.metadata.should eql(result)

      @session.should_receive(:metadata).once.with(@path, { :prior_response => result }).and_return(result)
      @entry.metadata.should eql(result)
    end

    it "... unless :force is set to true" do
      result = mock('result')

      @session.should_receive(:metadata).once.with(@path, {}).and_return(result)
      @entry.metadata

      @session.should_receive(:metadata).once.with(@path, {}).and_return(result)
      @entry.metadata(:force => true)
    end
  end

  describe "#move" do
    it "should delegate to the session and return the result" do
      result = mock('result')
      result.stub!(:path).and_return("newname")
      @session.should_receive(:move).once.with(@path, 'new/path', {}).and_return(result)

      @entry.move('new/path').should eql(result)
    end

    it "should pass along options" do
      result = mock('result')
      result.stub!(:path).and_return("newname")
      @session.should_receive(:move).once.with(@path, 'new/path', { :sandbox => true }).and_return(result)

      @entry.move('new/path', :sandbox => true)
    end

    it "should set the name according to the result" do
      result = mock('result')
      result.stub!(:path).and_return("resultname")
      @session.should_receive(:move).once.with(@path, 'new/path', {}).and_return(result)

      @entry.move('new/path')
      @entry.path.should eql('resultname')
    end
  end

  describe "#rename" do
    it "should delegate to the session and return the result" do
      result = mock('result')
      result.stub!(:path).and_return("newname")
      @session.should_receive(:rename).once.with(@path, 'newname', {}).and_return(result)

      @entry.rename('newname').should eql(result)
    end

    it "should pass along options" do
      result = mock('result')
      result.stub!(:path).and_return("newname")
      @session.should_receive(:rename).once.with(@path, 'newname', {}).and_return(result)

      @entry.rename('newname')
    end

    it "should set the name according to the result" do
      result = mock('result')
      result.stub!(:path).and_return("resultname")
      @session.should_receive(:rename).once.with(@path, 'newname', {}).and_return(result)

      @entry.rename('newname')
      @entry.path.should eql('resultname')
    end
  end

  describe "#copy" do
    it "should delegate to the session and return the result" do
      result = mock('result')
      @session.should_receive(:copy).once.with(@path, 'new/path', {}).and_return(result)

      @entry.copy('new/path').should eql(result)
    end

    it "should pass along options" do
      result = mock('result')
      @session.should_receive(:copy).once.with(@path, 'new/path', { :sandbox => true }).and_return(result)

      @entry.copy('new/path', :sandbox => true)
    end
  end

  describe "#delete" do
    it "should delegate to the session and return the result" do
      result = mock('result')
      @session.should_receive(:delete).once.with(@path, {}).and_return(result)

      @entry.delete.should eql(result)
    end

    it "should pass along options" do
      result = mock('result')
      @session.should_receive(:delete).once.with(@path, { :sandbox => true }).and_return(result)

      @entry.delete(:sandbox => true)
    end
  end

  describe "#download" do
    it "should delegate to the session and return the result" do
      result = mock('result')
      @session.should_receive(:download).once.with(@path, {}).and_return(result)

      @entry.download.should eql(result)
    end

    it "should pass along options" do
      result = mock('result')
      @session.should_receive(:download).once.with(@path, { :sandbox => true }).and_return(result)

      @entry.download(:sandbox => true)
    end
  end

  describe "#thumbnail" do
    it "should delegate to the session and return the result" do
      result = mock('result')
      @session.should_receive(:thumbnail).once.with(@path).and_return(result)

      @entry.thumbnail.should eql(result)
    end

    it "should pass along a size" do
      result = mock('result')
      @session.should_receive(:thumbnail).once.with(@path, 'medium').and_return(result)

      @entry.thumbnail('medium').should eql(result)
    end

    it "should pass along options" do
      result = mock('result')
      @session.should_receive(:thumbnail).once.with(@path, { :sandbox => true }).and_return(result)

      @entry.thumbnail(:sandbox => true).should eql(result)
    end

    it "should pass along a size and options" do
      result = mock('result')
      @session.should_receive(:thumbnail).once.with(@path, 'medium', { :sandbox => true }).and_return(result)

      @entry.thumbnail('medium', :sandbox => true).should eql(result)
    end
  end

  describe "#link" do
    it "should delegate to the session and return the result" do
      result = mock('result')
      @session.should_receive(:link).once.with(@path, {}).and_return(result)

      @entry.link.should eql(result)
    end

    it "should pass along options" do
      result = mock('result')
      @session.should_receive(:link).once.with(@path, { :sandbox => true }).and_return(result)

      @entry.link(:sandbox => true)
    end
  end

  describe "#list" do
    it "should use the session#list" do
      @session.should_receive(:list).and_return([])
      @entry.list
    end

    it "returns array of Entry objects" do
      result =
      1.upto(5).map do |i|
        struct = mock("struct#{i}")
        struct.stub(:path).and_return("/file#{i}")

        struct
      end
      @session.stub(:list).and_return(result)

      listing = @entry.list

      listing.should have(5).objects
      listing.each do |item|
        item.should be_instance_of(Dropbox::Entry)
      end
    end

    it "should throw :not_a_directory if session#list returns nil (path is not a directory)" do
      @session.stub(:list).and_return(nil)

      expect {@entry.list}.to throw_symbol :not_a_directory
    end
  end

  describe "#file" do
    it "returns a Tempfile object" do
      @session.stub(:download).and_return("Sample file content")
      @entry.stub(:directory?).and_return(false)

      @entry.file.should be_instance_of(Tempfile)
    end

    it "returns a file with correct content" do
      @session.stub(:download).and_return("Sample file content")
      @entry.stub(:directory?).and_return(false)

      @entry.file.read.should == "Sample file content"
    end

    it "should throw :not_a_file if path is not a file" do
      @entry.should_receive(:directory?).once.and_return(true)

      expect {@entry.file}.to throw_symbol :not_a_file
    end

    it "should return same file object if called twice" do
      @session.stub(:download).and_return("Sample file content")
      @entry.stub(:directory?).and_return(false)

      @entry.file.should == @entry.file
    end

    it "should recreate file if called with :force = true" do
      @session.stub(:download).and_return("Sample file content")
      @entry.stub(:directory?).and_return(false)

      @entry.file.should_not == @entry.file(:force => true)
    end
  end

  describe "#directory?" do
    it "should return true if path is a directory" do
      @session.stub_chain(:metadata, :directory?).and_return(true)

      @entry.directory?.should be_true
    end

    it "should return false if path is not a directory" do
      @session.stub_chain(:metadata, :directory?).and_return(false)

      @entry.directory?.should be_false
    end
  end
end
