# Defines the Dropbox::Memoization module.

nil # doc fix

module Dropbox

  # Adds methods to the Dropbox::Session class to support the temporary local
  # storage of API results to reduce the number of network calls and simplify
  # code.
  #
  # Memoization is <b>opt-in</b>; you must explicitly indicate that you want
  # this functionality by calling the enable_memoization method on your
  # Scribd::Session instance. Once memoization is enabled, subsequent calls to
  # memoized methods will hit an in-memory cache as opposed to making identical
  # network calls.
  #
  # If you would like to use your own caching strategy (for instance, your own
  # memcache instance), set the +cache_proc+ and +cache_clear_proc+ attributes.
  #
  # Enabling memoization makes removes an instance's thread-safety.
  #
  # Example:
  #
  #  session.metadata('file1') # network
  #
  #  session.enable_memoization
  #  session.metadata('file1') # network
  #  session.metadata('file1') # cache
  #
  #  session.metadata('file2') # network
  #  session.metadata('file2') # cache
  #
  #  session.disable_memoization
  #  session.metadata('file2') # network

  module Memoization
    def self.included(base) # :nodoc:
      base.extend ClassMethods
    end

    # The cache_proc is a proc with two arguments, the cache identifier and the
    # proc to call and store in the event of a cache miss:
    #
    #  instance.cache_proc = Proc.new do |identifier, calculate_proc|
    #    Rails.cache.fetch(identifier) { calculate_proc.call }
    #  end
    #
    # The Cache identifier will always be 64 lowercase hexadecimal characters.
    # The second argument is a curried proc including all arguments to the
    # original method call.

    def cache_proc=(prc)
      @_memo_cache_proc = prc
    end

    # The cache_clear_proc takes an identifier and should invalidate it from the
    # cache:
    #
    #  instance.cache_clear_proc = Proc.new { |identifier| Rails.cache.delete identifier }

    def cache_clear_proc=(prc)
      @_memo_cache_clear_proc = prc
    end

    # Begins memoizing the results of API calls. Memoization is off by default
    # for new instances.

    def enable_memoization
      @_memoize = true
      @_memo_identifiers ||= Set.new
    end

    # Halts memoization of API calls and clears the memoization cache.

    def disable_memoization
      @_memoize = false
      @_memo_identifiers.each { |identifier| (@_memo_cache_clear_proc || Proc.new { |ident| eval "@_memo_#{ident} = nil" }).call(identifier) }
      @_memo_identifiers.clear
    end

    module ClassMethods # :nodoc:
      def memoize(*method_names) # :nodoc:
        method_names.each do |meth|
          define_method :"#{meth}_with_memo" do |*args|
            if @_memoize then
              identifier = Digest::SHA1.hexdigest(meth.to_s + ":" + args.to_yaml)
              @_memo_identifiers << identifier
              (@_memo_cache_proc || Proc.new { |ident, calculate_proc| eval "@_memo_#{ident} ||= calculate_proc.call" }).call identifier, Proc.new { send :"#{meth}_without_memo", *args }
            else
              send :"#{meth}_without_memo", *args
            end
          end
          alias_method_chain meth, :memo
        end
      end
    end
  end
end
