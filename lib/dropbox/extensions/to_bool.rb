class FalseClass # :nodoc:
  def to_bool # :nodoc:
    false
  end unless method_defined?(:to_bool)
end

class NilClass # :nodoc:
  def to_bool # :nodoc:
    false
  end unless method_defined?(:to_bool)
end

class Object # :nodoc:
  def to_bool # :nodoc:
    true
  end unless method_defined?(:to_bool)
end