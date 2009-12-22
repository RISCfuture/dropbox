require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

def make_file_hash
  {
      :size => rand(1024*1024),
      :path => "/path/to/#{rand(100)}",
      :is_dir => (rand(2) == 0 ? true : false),
      :mtime => (Time.now - rand(60*60*24*30)).to_i,
      :latest => (rand(2) == 0 ? true : false)
  }
end

describe Dropbox::Event do
  before :each do
    @metadata = {
        '1' => {
            '10' => [ 100, 101, 102 ],
            '11' => [ 110, 111 ]
        },
        '2' => {
            '20' => [ 200, 201 ],
            '21' => [ 210 ]
        }
    }
    @event = Dropbox::Event.new(@metadata.to_json)
  end

  describe "#user_ids" do
    it "should return all the user ID's as integers" do
      @event.user_ids.sort.should eql([ 1, 2 ])
    end
  end

  describe "#entries" do
    describe "with no arguments" do
      it "should return all the entries as Dropbox::Revision instances" do
        entries = @event.entries
        entries.size.should eql(8)
        @metadata.each do |uid, ns|
          ns.each do |nid, js|
            js.each do |jid|
              entries.any? { |entry| entry.user_id == uid.to_i and entry.namespace_id == nid.to_i and entry.journal_id == jid.to_i }.should be_true
            end
          end
        end
      end

      it "should return a new array" do
        entries = @event.entries
        entries.clear
        @event.entries.should_not be_empty
      end
    end

    describe "with a user ID" do
      it "should return all the entries belonging to that user as Dropbox::Revision instances" do
        entries = @event.entries(2)
        entries.size.should eql(3)
        @metadata['2'].each do |nid, js|
          js.each do |jid|
            entries.any? { |entry| entry.user_id == 2 and entry.namespace_id == nid.to_i and entry.journal_id == jid.to_i }.should be_true
          end
        end
      end

      it "should return a new array" do
        entries = @event.entries(2)
        entries.clear
        @event.entries(2).should_not be_empty
      end

      it "should return an empty array for unknown user ID's" do
        @event.entries('foo').should be_empty
      end
    end
  end

  describe "#load_metadata" do
    before :each do
      @session = mock('Dropbox::Session')
    end
    
    it "should call Dropbox::Session#event_metadata" do
      @session.should_receive(:event_metadata).once.with(@metadata.to_json, {}).and_return({})
      @event.load_metadata(@session)
    end

    it "should pass options to Dropbox::Session#event_metadata" do
      @session.should_receive(:event_metadata).once.with(@metadata.to_json, :root => 'dropbox').and_return({})
      @event.load_metadata(@session, :root => 'dropbox')
    end

    it "should call Dropbox::Revision#process_metadata on all the revisions, passing symbolized keys" do
      metadata = {
        '1' => {
            '10' => {
                '100' => make_file_hash,
                '101' => make_file_hash,
                '102' => make_file_hash,
            },
            '11' => {
                '110' => make_file_hash,
                '111' => make_file_hash,
            }
        },
        '2' => {
            '20' => {
                '200' => { :error => 403 },
                '201' => { :error => 403 }
            },
            '21' => {
                '210' => { :error => 403 }
            }
        }
      }
      @session.stub!(:event_metadata).and_return(metadata)

      @event.entries.each { |entry| entry.should_receive(:process_metadata).once.with(metadata[entry.user_id.to_s][entry.namespace_id.to_s][entry.journal_id.to_s]) }
      @event.load_metadata(@session)
    end
  end
end


#describe Dropbox::Event do
#  before :each do
#    @session_mock = mock('Dropbox::Session')
#    @metadata = {
#        '100' => {
#            '10' => {
#                '1' => make_file_hash,
#                '2' => make_file_hash
#            },
#            '20' => {
#                '3' => make_file_hash,
#                '4' => { :error => 404 }
#            }
#        },
#        '200' => {
#            '30' => {
#                '5' => make_file_hash,
#                '6' => make_file_hash,
#                '7' => { :error => 403 }
#            }
#        }
#    }
#  end
#
#  describe "#user_ids" do
#    it "should return an array of Dropbox user ID's as integers" do
#      [ 100, 200 ].each { |num| @event.user_ids.should include(num) }
#      @event.user_ids.size.should eql(2)
#    end
#  end
#
#  describe "#entries" do
#    describe "with no arguments" do
#      it "should return Structs for every file" do
#        @event.entries.size.should eql(5)
#        @event.entries.each { |entry| entry.should be_kind_of(Struct) }
#      end
#
#      it "should return an empty array for unknown user ID's" do
#        @event.entries('foo').should be_empty
#      end
#    end
#
#    describe "with a Dropbox user ID" do
#      it "should return Structs for the user's files" do
#        @event.entries(100).size.should eql(3)
#        @event.entries(100).each { |entry| entry.should be_kind_of(Struct) }
#        @event.entries(200).size.should eql(2)
#        @event.entries(200).each { |entry| entry.should be_kind_of(Struct) }
#      end
#    end
#  end
#
#  describe "#errors" do
#    describe "with no arguments" do
#      it "should return Structs for every error" do
#        @event.errors.size.should eql(2)
#        @event.errors.each { |entry| entry.should be_kind_of(Struct) }
#      end
#
#      it "should return an empty array for unknown user ID's" do
#        @event.errors('foo').should be_empty
#      end
#    end
#
#    describe "with a Dropbox user ID" do
#      it "should return Structs for the user's file errors" do
#        @event.errors(100).size.should eql(1)
#        @event.errors(100).each { |entry| entry.should be_kind_of(Struct) }
#      end
#    end
#  end
#
#  describe "#entries_and_errors" do
#    describe "with no arguments" do
#      it "should return Structs for every file" do
#        @event.entries_and_errors.size.should eql(7)
#        @event.entries_and_errors.each { |entry| entry.should be_kind_of(Struct) }
#      end
#
#      it "should return an empty array for unknown user ID's" do
#        @event.entries_and_errors('foo').should be_empty
#      end
#    end
#
#    describe "with a Dropbox user ID" do
#      it "should return Structs for the user's files" do
#        @event.entries_and_errors(100).size.should eql(4)
#        @event.entries_and_errors(100).each { |entry| entry.should be_kind_of(Struct) }
#        @event.entries_and_errors(200).size.should eql(3)
#        @event.entries_and_errors(200).each { |entry| entry.should be_kind_of(Struct) }
#      end
#    end
#  end
#
#  describe "entry Struct" do
#    before :each do
#      @hash = make_file_hash
#      @metadata.clear
#      @metadata['100'] = { '10' => { '1' => @hash } }
#      @event = Dropbox::Event.new(@session, @metadata)
#    end
#
#    it "should mimic the hash" do
#      struct = @event.entries.first
#      [ :size, :path, :is_dir, :latest ].each { |key| @hash[key].should eql(struct.send(key)) }
#    end
#
#    it "should set the size to nil if -1" do
#      @metadata['100']['10']['1'][:size] = -1
#      @event = Dropbox::Event.new(@session, @metadata)
#      struct = @event.entries.first
#
#      struct.size.should be_nil
#    end
#
#    it "should set the mtime to nil if -1" do
#      @metadata['100']['10']['1'][:mtime] = -1
#      @event = Dropbox::Event.new(@session, @metadata)
#      struct = @event.entries.first
#
#      struct.mtime.should be_nil
#    end
#
#    it "should convert the mtime to a Time" do
#      time = Time.now
#      @metadata['100']['10']['1'][:mtime] = time.to_i
#      @event = Dropbox::Event.new(@session, @metadata)
#      struct = @event.entries.first
#
#      struct.mtime.should be_kind_of(Time)
#      struct.mtime.to_i.should eql(time.to_i)
#    end
#
#    it "should include a directory? predicate method" do
#      @metadata['100']['10']['1'][:is_dir] = true
#      @event = Dropbox::Event.new(@session, @metadata)
#      struct = @event.entries.first
#      struct.directory?.should be_true
#
#      @metadata['100']['10']['1'][:is_dir] = false
#      @event = Dropbox::Event.new(@session, @metadata)
#      struct = @event.entries.first
#      struct.directory?.should be_false
#    end
#
#    it "should include a latest? predicate method" do
#      @metadata['100']['10']['1'][:latest] = true
#      @event = Dropbox::Event.new(@session, @metadata)
#      struct = @event.entries.first
#      struct.latest?.should be_true
#
#      @metadata['100']['10']['1'][:latest] = false
#      @event = Dropbox::Event.new(@session, @metadata)
#      struct = @event.entries.first
#      struct.latest?.should be_false
#    end
#
#    it "should include a Dropbox::Entry for the file" do
#      @metadata['100']['10']['1'][:path] = "/some/path"
#      @event = Dropbox::Event.new(@session, @metadata)
#      struct = @event.entries.first
#
#      struct.entry.should be_kind_of(Dropbox::Entry)
#      struct.entry.path.should eql("/some/path")
#    end
#
#    it "should include the user_id" do
#      struct = @event.entries.first
#      struct.user_id.should eql(100)
#    end
#
#    it "should include the namespace_id" do
#      struct = @event.entries.first
#      struct.namespace_id.should eql(10)
#    end
#
#    it "should include the journal_id" do
#      struct = @event.entries.first
#      struct.journal_id.should eql(1)
#    end
#
#    it "should include the identifier" do
#      struct = @event.entries.first
#      struct.identifier.should eql("100:10:1")
#    end
#  end
#
#  describe "error Struct" do
#    before :each do
#      @metadata.clear
#      @metadata['100'] = { '10' => { '1' => { :error => 403 } } }
#      @event = Dropbox::Event.new(@session, @metadata)
#    end
#
#    it "should mimic the hash" do
#      struct = @event.errors.first
#      struct.error.should eql(403)
#    end
#
#    it "should include the user_id" do
#      struct = @event.errors.first
#      struct.user_id.should eql(100)
#    end
#
#    it "should include the namespace_id" do
#      struct = @event.errors.first
#      struct.namespace_id.should eql(10)
#    end
#
#    it "should include the journal_id" do
#      struct = @event.errors.first
#      struct.journal_id.should eql(1)
#    end
#
#    it "should include the identifier" do
#      struct = @event.errors.first
#      struct.identifier.should eql("100:10:1")
#    end
#
#    it "should not include other keys" do
#      struct = @event.errors.first
#      [ :size, :path, :is_dir, :latest ].each { |key| struct.members.should_not include(key) }
#    end
#  end
#end