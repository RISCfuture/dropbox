# Defines the Dropbox::Entry class.

nil # doc fix

module Dropbox

  # A façade over a Dropbox::Session that allows the programmer to interact with
  # Dropbox files in an object-oriented manner. The Dropbox::Entry instance is
  # created by calling the Dropbox::API#entry method:
  #
  #  file = session.file('remote/file.pdf')
  #  dir = session.directory('remote/dir') # these calls are actually identical
  #
  # Note that no network calls are made; this merely creates a façade that will
  # delegate future calls to the session:
  #
  #  file.move('new/path') # identical to calling session.move('remote/file.pdf', 'new/path')
  #
  # The internal path is updated as the file is moved and renamed:
  #
  #  file = session.file('first_name.txt')
  #  file.rename('second_name.txt')
  #  file.rename('third_name.txt') # works as the internal path is updated with the first rename

  class Entry
    # The remote path of the file.
    attr_reader :path

    def initialize(session, path) # :nodoc:
      @session = session
      @path = path
    end

    def self.create_from_metadata(session, metadata)
      entry = new(session, metadata.path)
      entry.metadata = metadata

      entry
    end

    # Delegates to Dropbox::API#metadata. Additional options:
    #
    # +force+:: Normally, subsequent calls to this method will use cached
    #           results. To download the full metadata set this to +true+.

    def metadata(options={})
      @metadata = nil if options.delete(:force)
      return @metadata if @metadata

      update_metadata(options)
    end
    alias :info :metadata

    # Use this method to update cached @metadata hash
    #
    # @param [Hash] options
    # @option options [Boolean] :force  Normally, subsequent calls to this method will use cached
    #                                   results if the file hasn't been changed. To download the full
    #                                   metadata even if the file has not been changed, set this to
    #                                   +true+.
    #
    def update_metadata(options={})
      @metadata = nil if options.delete(:force)
      @metadata = @session.metadata path, (@metadata ? options.merge(:prior_response => @metadata) : options)
    end

    # @param [Struct] new_metadata
    def metadata=(new_metadata)
      raise ArgumentError, "#{new_metadata.inspect} does not respond to #path" unless new_metadata.respond_to?(:path)

      @path = new_metadata.path
      @metadata = new_metadata
    end
    alias :info= :metadata=

    #
    # @return [Array<Dropbox::Entry>]
    # @throw :not_a_directory
    # use Dropbox::API#list

    def list(options={})
      ## load metadata first
      #meta = metadata(options)

      update_metadata(options)
      throw :not_a_directory unless directory?

      metadata.contents.map do |struct|
        self.class.create_from_metadata(@session, struct)
      end
    end
    alias :ls :list

    # Delegates to Dropbox::API#move.

    def move(dest, options={})
      result = @session.move(path, dest, options)
      @path = result.path.gsub(/^\//, '')
      return result
    end
    alias :mv :move

    # Delegates to Dropbox::API#rename.

    def rename(name, options={})
      result = @session.rename(path, name, options)
      @path = result.path.gsub(/^\//, '')
      return result
    end

    # Delegates to Dropbox::API#copy.

    def copy(dest, options={})
      @session.copy path, dest, options
    end
    alias :cp :copy

    # Delegates to Dropbox::API#delete.

    def delete(options={})
      @session.delete path, options
    end
    alias :rm :delete

    # Delegates to Dropbox::API#download.

    def download(options={})
      @session.download path, options
    end
    alias :body :download

    # Delegates to Dropbox::API#thumbnail.

    def thumbnail(*args)
      @session.thumbnail path, *args
    end

    # Delegates to Dropbox::API#link.

    def link(options={})
      @session.link path, options
    end

    #
    # @param [Hash] options
    # @option options [Boolean] :force create new file instead of using cached one
    # @return [Tempfile]
    # @throw :not_a_file
    def file(options={})
      throw :not_a_file if directory?
      return @cached_file if @cached_file && !options[:force]

      file = Tempfile.new('downloaded', :encoding => "BINARY")
      file.write download
      file.rewind

      @cached_file = file
    end

    # @return [Boolean]
    def directory?
      metadata.directory?
    end

    def inspect # :nodoc:
      "#<#{self.class.to_s} #{path}>"
    end
  end
end
