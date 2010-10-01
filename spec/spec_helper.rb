$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'rubygems'
require 'dropbox.rb'
require 'spec'
require 'spec/autorun'

module ExternalKeysFileHelper
  def read_keys_file
    keys_file_contents = open("keys.json", "r").read()
    JSON.parse(keys_file_contents)
  end
end

Spec::Runner.configure do |config|
  config.include(ExternalKeysFileHelper)
end
