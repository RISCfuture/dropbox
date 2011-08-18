require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Dropbox::Entry do
  before :each do
    @session = mock('Dropbox::Session')
    @path = 'test/path/to/file'
    @entry = Dropbox::Entry.new(@session, @path)
    #TODO this constructor is opaque
  end

  describe "#metadata" do
    before(:each) do
      @struct = stub('struct')
    end
    it "should delegate to the session and return the result" do
      @session.should_receive(:metadata).once.with(@path, {}).and_return(@struct)

      @entry.metadata.should eql(@struct)
    end

    it "should pass along options" do
      @session.should_receive(:metadata).once.with(@path, { :sandbox => true }).and_return(@struct)

      @entry.metadata(:sandbox => true)
    end

    describe "caching" do
      before(:each) do
        # first call
        @session.should_receive(:metadata).once.with(@path, {}).and_return(@struct)
        @entry.metadata.should eql @struct
      end

      it "should cache prior responses and use them instead of querying Dropbox" do
        # second call
        @session.should_not_receive(:metadata)
        @entry.metadata.should eql @struct
      end

      it "... unless :ignore_cache is set to true" do
        # second call
        @session.should_receive(:metadata).once.with(@path, { :prior_response => @struct }).and_return(@struct)
        @entry.metadata(:ignore_cache => true).should eql @struct
      end

      it "... unless :force is set to true" do
        # second call
        @session.should_receive(:metadata).once.with(@path, {}).and_return(@struct)
        @entry.metadata(:force => true).should eql @struct
      end
    end
  end

  describe "#update_metadata" do
    before(:each) do
      @struct = stub('struct')
    end
    it "should delegate to the session and return the result" do
      @session.should_receive(:metadata).once.with(@path, {}).and_return(@struct)

      @entry.update_metadata.should eql(@struct)
    end

    it "should pass along options" do
      @session.should_receive(:metadata).once.with(@path, { :sandbox => true }).and_return(@struct)

      @entry.update_metadata(:sandbox => true)
    end

    describe "caching" do
      before(:each) do
        # first call
        @session.should_receive(:metadata).once.with(@path, {}).and_return(@struct)
        @entry.update_metadata.should eql @struct
      end

      it "should record prior responses and use them automatically" do
        # second call
        @session.should_receive(:metadata).once.with(@path, { :prior_response => @struct }).and_return(@struct)
        @entry.update_metadata.should eql(@struct)
      end

      it "... unless :force is set to true" do
        # second call
        @session.should_receive(:metadata).once.with(@path, {}).and_return(@struct)
        @entry.update_metadata(:force => true).should eql @struct
      end
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
    context "entry is a directory" do
      before(:each) do
        @dir_metadata = mock('dir_metadata')
        @dir_metadata.should_receive(:directory?).and_return(true)
        @dir_metadata.stub(:path).and_return('/dir')
        @session.stub(:metadata).and_return(@dir_metadata)
      end

      it "returns directory objects" do
        result =
        1.upto(5).map do |i|
          struct = mock("struct#{i}")
          struct.stub(:path).and_return("/file#{i}")

          struct
        end
        @dir_metadata.should_receive(:contents).and_return(result)

        listing = @entry.list

        listing.should have(5).objects
        listing.each do |item|
          item.should be_instance_of(Dropbox::Entry)
        end
      end

      it "should set metadata for directory objects" do
        file_metadata = stub('file_metadata')
        file_metadata.stub(:path).and_return('/file')

        @dir_metadata.should_receive(:contents).and_return([file_metadata])

        listing = @entry.list
        listing.should have(1).object

        listing.first.metadata.should == file_metadata
      end

      context "has contents metadata loaded already" do
        before(:each) do
          @dir_metadata.should_receive(:contents).and_return([])
          @entry.metadata = @dir_metadata
        end

        it "should not call session.metadata" do
          @session.should_not_receive(:metadata)
          @entry.list
        end

        it "... unless :ignore_cache is set to true" do
          @session.should_receive(:metadata).and_return(@dir_metadata)
          @entry.list(:ignore_cache => true)
        end

        it "... unless :force is set to true" do
          @session.should_receive(:metadata).and_return(@dir_metadata)
          @entry.list(:force => true)
        end
      end

      context "has not contents metadata (its nil)" do
        it "should call session.metadata" do
          @dir_metadata.stub(:contents).and_raise(NoMethodError)
          @entry.metadata = @dir_metadata

          new_metadata = mock('new_metadata')
          new_metadata.should_receive(:contents).and_return([])
          @session.should_receive(:metadata).and_return(new_metadata)
          @entry.list
        end


      end
    end

    it "should throw :not_a_directory if path is not a directory" do
      @session.stub_chain(:metadata, :directory?).and_return(false)

      expect {@entry.list}.to throw_symbol :not_a_directory
    end
  end

  describe "#file" do
    before(:each) do
      @session.stub(:download).and_return("Sample file content")
      @entry.stub(:directory?).and_return(false)
    end
    specify{ @entry.file.should be_instance_of(Tempfile) }


    it "returns a file with correct content" do
      @entry.file.read.should == "Sample file content"
    end

    it "should throw :not_a_file if path is not a file" do
      @entry.should_receive(:directory?).once.and_return(true)

      expect {@entry.file}.to throw_symbol :not_a_file
    end

    it "should return same file object if called twice" do
      @entry.file.should == @entry.file
    end

    it "should recreate file if called with :force = true" do
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

  describe "#create_from_metadata" do
    it "should set path and metadata to new Entry object" do
      metadata = mock('metadata').as_null_object
      metadata.should_receive(:path).at_least(1).times.and_return('/file')

      entry = Dropbox::Entry.create_from_metadata(@session, metadata)

      entry.path.should == metadata.path
      entry.metadata.should == metadata
    end
  end
end
