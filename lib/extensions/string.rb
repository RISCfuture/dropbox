class String # :nodoc:
  def starts_with?(prefix) # :nodoc:
    self[0, prefix.length] == prefix
  end unless method_defined?(:starts_with?)
end
