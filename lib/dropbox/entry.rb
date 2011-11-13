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

    # Delegates to Dropbox::Entry#update_metadata. Use caching.
    #
    # @param [Hash] options
    # @option options [Boolean] :ignore_cache Normally, subsequent calls to this method will use cached
    #                                         results. To download the full metadata set this to +true+.
    # @option (see Dropbox::Entry#update_metadata)
    def metadata(options={})
      @cached_metadata = nil if options.delete(:ignore_cache) or options[:force]
      return @cached_metadata if @cached_metadata

      update_metadata(options)
    end
    alias :info :metadata

    # @param [Hash] options
    # @option options [Boolean] :force  Normally, subsequent calls to this method will use cached
    #                                   results if the file hasn't been changed. To download the full
    #                                   metadata even if the file has not been changed, set this to
    #                                   +true+.
    #
    def update_metadata(options={})
      @previous_metadata ||= @cached_metadata

      @previous_metadata = nil if options.delete(:force)
      @previous_metadata = @session.metadata path, (@previous_metadata ? options.merge(:prior_response => @previous_metadata) : options)

      @cached_metadata = @previous_metadata
    end

    # @param [Struct] new_metadata
    def metadata=(new_metadata)
      raise ArgumentError, "#{new_metadata.inspect} does not respond to #path" unless new_metadata.respond_to?(:path)

      @path = new_metadata.path
      @cached_metadata = new_metadata
    end
    alias :info= :metadata=

    #
    # @return [Array<Dropbox::Entry>]
    # @throw :not_a_directory
    # use Dropbox::API#list

    def list(options={})
      # load metadata first
      metadata(options)
      throw :not_a_directory unless directory?

      begin
        contents = metadata.contents
      rescue NoMethodError
        contents = metadata(options.merge(:ignore_cache => true)).contents
      end

      contents.map do |struct|
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

      ext  = ::File.extname(path)
      name = ::File.basename(path, ext)

      file = Tempfile.new([name, ext], :encoding => "BINARY")
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
