class String # :nodoc:
  def starts_with?(prefix) # :nodoc:
    self[0, prefix.length] == prefix
  end unless method_defined?(:starts_with?)

  def ends_with?(suffix) # :nodoc:
    self[-suffix.length, suffix.length] == suffix
  end unless method_defined?(:ends_with?)
end
