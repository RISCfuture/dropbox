$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'rubygems'
require 'dropbox.rb'
require 'spec'
require 'spec/autorun'

module ExternalKeysFileHelper
  def read_keys_file
    unless File.exist?('keys.json')
      raise "Please add a keys.json file to the project directory containing your Dropbox API key and secret. See keys.json.example to get started."
    end
    
    keys_file_contents = open("keys.json", "r").read()
    data = JSON.parse(keys_file_contents)
    unless %w( key secret email password ).all? { |key| data.include? key }
      raise "Your keys.json file does contain all the required information. See keys.json.example for more help."
    end
    
    data
  end
end

Spec::Runner.configure do |config|
  config.include(ExternalKeysFileHelper)
end
