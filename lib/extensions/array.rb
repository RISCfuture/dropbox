class Array # :nodoc:
  def extract_options! # :nodoc:
    last.is_a?(::Hash) ? pop : {}
  end unless method_defined?(:extract_options!)
end
