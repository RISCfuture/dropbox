# Defines the Dropbox::File class.

module Dropbox

  # A façade over a Dropbox::Session that allows the programmer to interact with
  # Dropbox files in an object-oriented manner. The Dropbox::Entry instance is
  # created by calling the Dropbox::Session#file method:
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

    # Delegates to Dropbox::Session#metadata.

    def metadata(options={})
      @session.metadata path, options
    end
    alias :info :metadata

    def list(options={})
      @session.list path, options
    end
    alias :ls :list

    # Delegates to Dropbox::Session#move.

    def move(dest, options={})
      result = @session.move(path, dest, options)
      @path = result.path.gsub(/^\//, '')
      return result
    end
    alias :mv :move

    # Delegates to Dropbox::Session#rename.

    def rename(name, options={})
      result = @session.rename(path, name, options)
      @path = result.path.gsub(/^\//, '')
      return result
    end

    # Delegates to Dropbox::Session#copy.

    def copy(dest, options={})
      @session.copy path, dest, options
    end
    alias :cp :copy

    # Delegates to Dropbox::Session#delete.

    def delete(options={})
      @session.delete path, options
    end
    alias :rm :delete

    # Delegates to Dropbox::Session#download.

    def download(options={})
      @session.download path, options
    end
    alias :body :download

    # Delegates to Dropbox::Session#link.

    def link(options={})
      @session.link path, options
    end

    def inspect # :nodoc:
      "#<#{self.class.to_s} #{path}>"
    end
  end
end