class Object # :nodoc:
  def to_bool # :nodoc:
    true
  end
end

class FalseClass # :nodoc:
  def to_bool # :nodoc:
    false
  end
end

class NilClass # :nodoc:
  def to_bool # :nodoc:
    false
  end
end
