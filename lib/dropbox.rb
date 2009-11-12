# Defines the Dropbox module.

require 'cgi'
require 'yaml'

Dir.glob("#{File.expand_path File.dirname(__FILE__)}/extensions/*.rb") { |file| require file }
Dir.glob("#{File.expand_path File.dirname(__FILE__)}/dropbox/*.rb") { |file| require file }

# Container module for the all Dropbox API classes.

module Dropbox
  # The API version this client works with.
  VERSION = "0"
  # The host serving API requests.
  HOST = "http://api.dropbox.com"

  def self.api_url(*paths_and_options) # :nodoc:
    params = paths_and_options.extract_options!
    url = "#{HOST}/#{VERSION}/#{paths_and_options.map { |path_elem| CGI.escape path_elem.to_s }.join('/')}"
    url.gsub! '+', '%20' # dropbox doesn't really like plusses
    url << "?#{params.map { |k,v| CGI.escape(k.to_s) + "=" + CGI.escape(v.to_s) }.join('&')}" unless params.empty?
    return url
  end
end
