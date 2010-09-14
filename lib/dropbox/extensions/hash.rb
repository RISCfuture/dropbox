class Hash # :nodoc:
  def slice(*keys) #:nodoc:
    keys = keys.map! { |key| convert_key(key) } if respond_to?(:convert_key)
    hash = self.class.new
    keys.each { |k| hash[k] = self[k] if has_key?(k) }
    hash
  end unless method_defined?(:slice)

  def symbolize_keys # :nodoc:
    inject({}) do |options, (key, value)|
      options[(key.to_sym rescue key) || key] = value
      options
    end
  end unless method_defined?(:symbolize_keys)

  def symbolize_keys! # :nodoc:
    self.replace(self.symbolize_keys)
  end unless method_defined?(:symbolize_keys!)

  def symbolize_keys_recursively # :nodoc:
    hsh = symbolize_keys
    hsh.each { |k, v| hsh[k] = v.symbolize_keys_recursively if v.kind_of?(Hash) }
    hsh.each { |k, v| hsh[k] = v.map { |i| i.kind_of?(Hash) ? i.symbolize_keys_recursively : i } if v.kind_of?(Array) }
    return hsh
  end unless method_defined?(:symbolize_keys_recursively)

  def stringify_keys # :nodoc:
    inject({}) do |options, (key, value)|
      options[(key.to_s rescue key) || key] = value
      options
    end
  end unless method_defined?(:stringify_keys)

  def stringify_keys! # :nodoc:
    self.replace(self.stringify_keys)
  end unless method_defined?(:stringify_keys!)

  def stringify_keys_recursively # :nodoc:
    hsh = stringify_keys
    hsh.each { |k, v| hsh[k] = v.stringify_keys_recursively if v.kind_of?(Hash) }
    hsh.each { |k, v| hsh[k] = v.map { |i| i.kind_of?(Hash) ? i.stringify_keys_recursively : i } if v.kind_of?(Array) }
    return hsh
  end unless method_defined?(:stringify_keys_recursively)

  def to_struct # :nodoc:
    struct = Struct.new(*keys).new(*values)
    # attach methods for any predicate keys, since Struct.new doesn't seem to do that
    pred_keys = slice(*(keys.select { |key| key.to_s.ends_with?('?') }))
    pred_keys.each do |key, val|
      struct.eigenclass.send(:define_method, key.to_sym) { return val }
    end
    return struct
  end unless method_defined?(:to_struct)

  def to_struct_recursively # :nodoc:
    hsh = dup
    hsh.each { |k, v| hsh[k] = v.to_struct_recursively if v.kind_of?(Hash) }
    hsh.each { |k, v| hsh[k] = v.map { |i| i.kind_of?(Hash) ? i.to_struct_recursively : i } if v.kind_of?(Array) }
    return hsh.to_struct
  end unless method_defined?(:to_struct_recursively)
end
