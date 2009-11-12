class Hash # :nodoc:
  def symbolize_keys # :nodoc:
    inject({}) do |options, (key, value)|
      options[(key.to_sym rescue key) || key] = value
      options
    end
  end unless method_defined?(:symbolize_keys)

  def symbolize_keys! # :nodoc:
    self.replace(self.symbolize_keys)
  end unless method_defined?(:symbolize_keys!)
end
