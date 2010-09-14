class Array # :nodoc:
  def extract_options! # :nodoc:
    last.is_a?(::Hash) ? pop : {}
  end unless method_defined?(:extract_options!)

  def to_hash # :nodoc:
    inject({}) { |hsh, (k,v)| hsh[k] = v  ; hsh }
  end unless method_defined?(:to_hash)
end
