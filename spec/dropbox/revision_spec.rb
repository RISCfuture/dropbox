require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

def pretend_content_and_metadata_is_loaded(revision, session, options={})
  content = options[:content] || "Example Content"
  metadata = options[:metadata] || {
      :size => (options[:size] || rand(1024*1024)),
      :path => (options[:path] || "/path/to/#{rand 100}"),
      :is_dir => options[:is_dir].to_bool,
      :mtime => (options[:mtime] || (Time.now.to_i - rand(60*60*24*30))),
      :latest => options[:latest].to_bool
  }

  session.stub!(:event_content).and_return([ content, metadata ])
  revision.load session
  return metadata
end

def pretend_error_occurred(revision, error=404)
  revision.process_metadata :error => error
  return error
end

describe Dropbox::Revision do
  before :each do
    @uid = rand(1000)
    @nid = rand(1000)
    @jid = rand(1000)
    @revision = Dropbox::Revision.new(@uid, @nid, @jid)
  end

  describe ".new" do
    it "should set the user, namespace, and journal ID" do
      @revision.user_id.should eql(@uid)
      @revision.namespace_id.should eql(@nid)
      @revision.journal_id.should eql(@jid)
    end

    it "should not have an error" do
      @revision.should_not be_error
      @revision.error.should be_nil
    end

    it "should not have content loaded" do
      @revision.should_not be_content_loaded
    end

    it "should not have metadata loaded" do
      @revision.should_not be_metadata_loaded
    end
  end

  describe "#identifier" do
    it "should be the Dropbox event identifier for the revision" do
      @revision.identifier.should eql([ @uid, @nid, @jid ].map(&:to_s).join(':'))
    end
  end

  describe "#load" do
    before :each do
      @session = mock('Dropbox::Session')
    end

    it "should call Dropbox::API.event_content" do
      @session.should_receive(:event_content).once.with(@revision.identifier, {}).and_return([ "A", {} ])
      @revision.load @session
    end

    it "should pass options to the session" do
      @session.should_receive(:event_content).once.with(@revision.identifier, { :root => 'dropbox' }).and_return([ "A", {} ])
      @revision.load @session, :root => 'dropbox'
    end

    it "should set the content and metadata" do
      @session.stub!(:event_content).and_return([ "content", { :number => 123 } ])
      @revision.load @session

      @revision.content.should eql("content")
      @revision.number.should eql(123)
    end

    it "should work with metadata string keys" do
      @session.stub!(:event_content).and_return([ "content", { :number => 123 } ])
      @revision.load @session

      @revision.content.should eql("content")
      @revision.number.should eql(123)
    end

    it "should set the size attribute to nil if it's -1" do
      @session.stub!(:event_content).and_return([ "content", { :size => -1 } ])
      @revision.load @session

      @revision.size.should be_nil
    end

    it "should set the mtime attribute to nil if it's -1" do
      @session.stub!(:event_content).and_return([ "content", { :mtime => -1 } ])
      @revision.load @session

      @revision.mtime.should be_nil
    end

    it "should convert the mtime attribute to a Time" do
      time = Time.now.to_i
      @session.stub!(:event_content).and_return([ "content", { :mtime => time } ])
      @revision.load @session

      @revision.mtime.should be_kind_of(Time)
      @revision.mtime.to_i.should eql(time)
    end
  end

  describe "#content_loaded?" do
    it "should return true if the content is loaded" do
      pretend_content_and_metadata_is_loaded @revision, @session
      @revision.should be_content_loaded
    end
  end

  describe "#metadata_loaded?" do
    it "should return true if the metadata is loaded" do
      pretend_content_and_metadata_is_loaded @revision, @session
      @revision.should be_metadata_loaded
    end
  end

  describe "#latest?" do
    it "should raise an exception if the metadata is not yet loaded" do
      lambda { @revision.latest? }.should raise_error(Dropbox::NotLoadedError)
    end

    it "should return the true if latest is true" do
      pretend_content_and_metadata_is_loaded @revision, @session, :latest => true
      @revision.should be_latest
    end

    it "should return the false if latest is false" do
      pretend_content_and_metadata_is_loaded @revision, @session, :latest => false
      @revision.should_not be_latest
    end
  end

  describe "#directory?" do
    it "should raise an exception if the metadata is not yet loaded" do
      lambda { @revision.directory? }.should raise_error(Dropbox::NotLoadedError)
    end

    it "should return true if is_dir is true" do
      pretend_content_and_metadata_is_loaded @revision, @session, :is_dir => true
      @revision.should be_directory
    end

    it "should return false if is_dir is false" do
      pretend_content_and_metadata_is_loaded @revision, @session, :is_dir => false
      @revision.should_not be_directory
    end
  end

  describe "#modified" do
    it "should raise an exception if the metadata is not yet loaded" do
      lambda { @revision.modified }.should raise_error(Dropbox::NotLoadedError)
    end

    it "should return the mtime attribute" do
      md = pretend_content_and_metadata_is_loaded(@revision, @session)
      @revision.modified.should eql(md[:mtime])
    end
  end

  describe "#error?" do
    it "should return true if there was an error" do
      pretend_error_occurred @revision
      @revision.should be_error
    end

    it "should return false if there was not an error" do
      pretend_content_and_metadata_is_loaded @revision, @session
      @revision.should_not be_error
    end
  end
  
  describe "#deleted?" do
    it "should raise an exception if the metadata is not yet loaded" do
      lambda { @revision.deleted? }.should raise_error(Dropbox::NotLoadedError)
    end
    
    it "should return true if mtime and size are nil" do
      pretend_content_and_metadata_is_loaded(@revision, @session)
      @revision.stub!(:mtime).and_return(nil)
      @revision.stub!(:size).and_return(nil)
      @revision.should be_deleted
    end
    
    it "should return false if mtime and size are not nil" do
      pretend_content_and_metadata_is_loaded(@revision, @session)
      @revision.stub!(:mtime).and_return(Time.now)
      @revision.stub!(:size).and_return(123)
      @revision.should_not be_deleted
    end
  end

  describe "#content" do
    it "should raise an exception if the content is not yet loaded" do
      lambda { @revision.content }.should raise_error(Dropbox::NotLoadedError)
    end

    it "should return the file content" do
      pretend_content_and_metadata_is_loaded @revision, @session
      @revision.content.should eql("Example Content")
    end
  end

  describe "#method_missing" do
    before :each do
      pretend_content_and_metadata_is_loaded @revision, @session, :size => 123
    end

    it "should return a metadata attribute by name" do
      @revision.size.should eql(123)
    end

    it "... unless arguments are provided" do
      lambda { @revision.size(123) }.should raise_error(NoMethodError)
    end

    it "should raise NoMethodError for an unknown attribute" do
      lambda { @revision.foobar }.should raise_error(NoMethodError)
    end
  end

  describe "#metadata_for_latest_revision" do
    it "should raise an error if metadata has not yet been loaded" do
      lambda { @revision.metadata_for_latest_revision @session }.should raise_error(Dropbox::NotLoadedError)
    end

    it "should call Dropbox::API.metadata with its path" do
      pretend_content_and_metadata_is_loaded @revision, @session
      @session.should_receive(:metadata).once.with(@revision.path, {})
      @revision.metadata_for_latest_revision @session
    end

    it "should pass along options" do
      pretend_content_and_metadata_is_loaded @revision, @session
      @session.should_receive(:metadata).once.with(@revision.path, { :root => 'dropbox' })
      @revision.metadata_for_latest_revision @session, :root => 'dropbox'
    end
  end

  describe "#process_metadata" do
    describe "with an error" do
      before :each do
        @metadata = { :error => 403 }
      end

      it "should set the error attribute" do
        @revision.process_metadata @metadata
        @revision.error.should eql(403)
      end

      it "... unless the metadata has already been loaded" do
        pretend_content_and_metadata_is_loaded @revision, @session
        @revision.process_metadata @metadata
        @revision.error.should be_nil
      end

      it "should not change the metadata" do
        md = pretend_content_and_metadata_is_loaded @revision, @session
        @revision.process_metadata @metadata
        md.each { |key, val| @revision.send(key).should eql(val) }
      end
    end

    describe "with metadata" do
      before :each do
        @metadata = {
            :size => rand(1024*1024),
            :path => "/path/to/#{rand 100}",
            :is_dir => (rand(2) == 0),
            :mtime => (Time.now.to_i - rand(60*60*24*30)),
            :latest => (rand(2) == 0)
        }
      end

      it "should clear the error attribute" do
        pretend_error_occurred @revision
        @revision.process_metadata @metadata
        @revision.error.should be_nil
      end

      it "should assign metadata" do
        @revision.process_metadata @metadata
        @metadata.each { |key, val| @revision.send(key).should eql(val) unless key == :mtime }
      end

      it "should clear and overwrite old metadata" do
        pretend_content_and_metadata_is_loaded @revision, @session
        @revision.process_metadata @metadata
        @metadata.each { |key, val| @revision.send(key).should eql(val) unless key == :mtime }
      end

      it "should set the size attribute to nil if it's -1" do
        @metadata[:size] = -1
        @revision.process_metadata @metadata
        @revision.size.should be_nil
      end
      
      it "should set the mtime attribute to nil if it's -1" do
        @metadata[:mtime] = -1
        @revision.process_metadata @metadata
        @revision.mtime.should be_nil
      end

      it "should convert the mtime attribute to a Time" do
        time = Time.now.to_i
        @metadata[:mtime] = time
        @revision.process_metadata @metadata

        @revision.mtime.should be_kind_of(Time)
        @revision.mtime.to_i.should eql(time)
      end
    end
  end
end