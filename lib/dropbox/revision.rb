# Defines the Dropbox::Revision class.

nil # doc fix

module Dropbox

  # A file or folder at a point in time as referenced by a Dropbox::Event
  # pingback event. Instances start out as "shells" only storing enough
  # information to uniquely identify a file/folder belonging to a user at a
  # certain revision.
  #
  # Instances of this class only appear in a Dropbox::Event object. To load the
  # metadata for a revision, use the Dropbox::Event#load_metadata method.
  # To load the content of the file at this revision, use the load_content
  # method on this class.
  #
  # Once the metadata has been loaded, you can access it directly:
  #
  #  revision.size #=> 2962
  #
  # The +mtime+ attribute will be a Time instance.  The +mtime+ and +size+
  # attributes will be +nil+ (not -1) if the file was deleted. All other
  # attributes are as defined in
  # http://developers.getdropbox.com/base.html#event-metadata
  #
  # If the metadata could not be read for whatever reason, the HTTP error code
  # will be stored in the +error+ attribute.

  class Revision
    # The ID of the Dropbox user that owns this file.
    attr_reader :user_id
    # The namespace ID of the file (Dropbox internal).
    attr_reader :namespace_id
    # The journal ID of the file (Dropbox internal).
    attr_reader :journal_id
    # The HTTP error code received when trying to load metadata, or +nil+ if no
    # error has yet been received.
    attr_reader :error

    def initialize(uid, nid, jid) # :nodoc:
      @user_id = uid
      @namespace_id = nid
      @journal_id = jid
    end

    # The unique identifier string used by some Dropbox event API methods.

    def identifier
      "#{user_id}:#{namespace_id}:#{journal_id}"
    end

    # Uses the given Dropbox::Session to load the content and metadata for a
    # file at a specific revision.
    #
    # Options:
    #
    # +mode+:: Temporarily changes the API mode. See the Dropbox::API::MODES
    #          array.

    def load(session, options={})
      @content, @metadata = session.event_content(identifier, options)
      @metadata.symbolize_keys!

      postprocess_metadata
    end

    # Returns true if the content for this revision has been previously loaded
    # and is cached in this object.

    def content_loaded?
      @content.to_bool
    end

    # Returns true if the metadata for this revision has been previously loaded
    # and is cached in this object.

    def metadata_loaded?
      @metadata.to_bool
    end

    # Sugar for the +latest+ attribute.

    def latest?
      raise NotLoadedError.new(:metadata) unless metadata_loaded?
      self.latest
    end

    # Sugar for the +is_dir+ attribute.

    def directory?
      raise NotLoadedError.new(:metadata) unless metadata_loaded?
      self.is_dir
    end

    # Synonym for the +mtime+ attribute, for "duck" compatibility with the
    # Dropbox +metadata+ API.

    def modified
      raise NotLoadedError.new(:metadata) unless metadata_loaded?
      self.mtime
    end

    # Returns true if an error occurred when trying to load metadata.

    def error?
      error.to_bool
    end

    # Returns the contents of the file as a string. Returns nil for directories.
    # You must call load first to retrieve the content from the network.

    def content
      raise NotLoadedError.new(:content) unless content_loaded?
      @content
    end

    def inspect # :nodoc:
      "#<#{self.class.to_s} #{identifier}>"
    end

    # Allows you to access metadata attributes directly:
    #
    #  revision.size #=> 10526
    #
    # A NoMethodError will be raised if the metadata has not yet been loaded for
    # this revision, so be sure to call metadata_loaded? beforehand.

    def method_missing(meth, *args)
      if args.empty? then
        if @metadata and @metadata.include?(meth) then
          return @metadata[meth]
        else
          super
        end
      else
        super
      end
    end

    # Loads the metadata for the latest revision of the entry and returns it as
    # as <tt>Struct</tt> object. Uses the given session and calls
    # Dropbox::API.metadata.
    #
    # If the metadata for this object has not yet been loaded, raises an error.
    # Options are passed to Dropbox::API.metadata.

    def metadata_for_latest_revision(session, options={})
      raise NotLoadedError.new(:metadata) unless metadata_loaded?
      session.metadata self.path, options
    end

    def process_metadata(metadata) # :nodoc:
      if metadata[:error] then
        @error = metadata[:error] unless @metadata
        return
      end

      @error = nil
      @metadata = Hash.new
      metadata.each { |key, value| @metadata[key.to_sym] = value }

      postprocess_metadata
    end

    private

    def postprocess_metadata
      @metadata[:size] = nil if @metadata[:size] == -1
      @metadata[:mtime] = (@metadata[:mtime] == -1 ? nil : Time.at(@metadata[:mtime])) if @metadata[:mtime]
    end
  end

  # Raised when trying to access content metadata before it has been loaded.

  class NotLoadedError < StandardError
    
    # What data did you attempt to access before it was loaded? Either
    # <tt>:content</tt> or <tt>:metadata</tt>.
    attr_reader :data

    def initialize(data) # :nodoc:
      @data = data
    end

    def to_s # :nodoc:
      "#{data.capitalize} not yet loaded -- call #load on the Dropbox::Revision instance beforehand"
    end
  end
end
