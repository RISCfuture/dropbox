class Object # :nodoc:
  def eigenclass # :nodoc:
    (class << self; self; end)
  end unless method_defined?(:eigenclass)
end
