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
