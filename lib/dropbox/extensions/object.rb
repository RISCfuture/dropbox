class Object # :nodoc:
  def eigenclass # :nodoc:
    (class << self; self; end)
  end
end
