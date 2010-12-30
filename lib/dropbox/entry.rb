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

    # Delegates to Dropbox::API#metadata. Additional options:
    #
    # +force+:: Normally, subsequent calls to this method will use cached
    #           results if the file hasn't been changed. To download the full
    #           metadata even if the file has not been changed, set this to
    #           +true+.

    def metadata(options={})
      @previous_metadata = nil if options.delete(:force)
      @previous_metadata = @session.metadata path, (@previous_metadata ? options.merge(:prior_response => @previous_metadata) : options)
    end
    alias :info :metadata
    
    # Delegates to Dropbox::API#list

    def list(options={})
      @session.list path, options
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

    def inspect # :nodoc:
      "#<#{self.class.to_s} #{path}>"
    end
  end
end
