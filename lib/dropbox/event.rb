# Defines the Dropbox::Event class.

nil # doc fix

module Dropbox
  
  # The Dropbox::Event class stores information about which entries were
  # modified during a pingback event. You initialize this class from the JSON
  # string given to you by Dropbox during a pingback:
  #
  #  event = Dropbox::Event.new(params[:target_events])
  #
  # Once this is complete, the Dropbox::Event instance contains references for
  # each of the entries, with the basic information included in the pingback:
  #
  #  event.user_ids #=> [ 1, 2, 3 ]
  #  event.entries(1).first #=> #<Dropbox::Revision 1:10:100>
  #
  # For any of these entries, you can load its content and metadata:
  #
  #  event.entries(1).first.load(dropbox_session)
  #  event.entries(1).first.content #=> "Content of file..."
  #  event.entries(1).first.size #=> 2245
  #
  # You can also load only the metadata for all of a user's entries:
  #
  #  event.load_metadata(first_users_dropbox_session)
  #  event.entries(1).first.size #=> 154365
  
  class Event
    def initialize(json_pingback) # :nodoc:
      @json_pingback = json_pingback
      begin
        @metadata = JSON.parse(json_pingback).stringify_keys_recursively
      rescue JSON::ParserError
        raise Dropbox::ParseError, "Invalid pingback event data"
      end

      process_pingback
    end
    
    # Returns an array of Dropbox user ID's involved in this pingback.
    
    def user_ids
      @entries_by_user_id.keys
    end

    # When given no arguments, returns an array of all entries (as
    # Dropbox::Revision instances). When given a user ID, filters the list
    # to only entries belonging to that Dropbox user.

    def entries(user_id=nil)
      user_id ? (@entries_by_user_id[user_id.to_i] || []).dup : @entries.dup
    end

    # Loads the metadata for all entries belonging to a given Dropbox session.
    # Does not load data for files that do not belong to the user owning the
    # given Dropbox session.
    #
    # Future calls to this method will result in additional network requests,
    # though the Dropbox::Revision instances do cache their metadata values.
    #
    # Options:
    #
    # +mode+:: Temporarily changes the API mode. See the Dropbox::API::MODES
    #          array.

    def load_metadata(session, options={})
      process_metadata session.event_metadata(@json_pingback, options).stringify_keys_recursively
    end
    
    def inspect # :nodoc:
      "#<#{self.class.to_s} (#{@entries.size} entries)>"
    end
    
    private

    def process_pingback
      @entries = Array.new
      @entries_by_user_id = Hash.new
      @entries_hashed = Hash.new

      @metadata.each do |user_id, namespaces|
        @entries_hashed[user_id.to_i] = Hash.new
        @entries_by_user_id[user_id.to_i] = Array.new
        namespaces.each do |namespace_id, journals|
          @entries_hashed[user_id.to_i][namespace_id.to_i] = Hash.new
          journals.each do |journal_id|
            entry = Dropbox::Revision.new(user_id.to_i, namespace_id.to_i, journal_id.to_i)
            @entries << entry
            @entries_by_user_id[user_id.to_i] << entry
            @entries_hashed[user_id.to_i][namespace_id.to_i][journal_id.to_i] = entry
          end
        end
      end
    end

    def process_metadata(metadata)
      p metadata
      metadata.each do |user_id, namespaces|
        namespaces.each do |namespace_id, journals|
          journals.each do |journal_id, attributes|
            @entries_hashed[user_id.to_i][namespace_id.to_i][journal_id.to_i].process_metadata(attributes.symbolize_keys)
          end
        end
      end
    end
  end
end
