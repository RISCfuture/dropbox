# Defines the Dropbox module.

require 'cgi'
require 'yaml'
require 'digest/sha1'
require 'thread'
require 'set'
require 'time'
require 'tempfile'

Dir.glob("#{File.expand_path File.dirname(__FILE__)}/extensions/*.rb") { |file| require file }
Dir.glob("#{File.expand_path File.dirname(__FILE__)}/dropbox/*.rb") { |file| require file }

# Container module for the all Dropbox API classes.

module Dropbox
  # The API version this client works with.
  VERSION = "0"
  # The host serving API requests.
  HOST = "http://api.dropbox.com"
  # Alternate hosts for other API requests.
  ALTERNATE_HOSTS = { 'files' => "http://api-content.dropbox.com" }

  def self.api_url(*paths_and_options) # :nodoc:
    params = paths_and_options.extract_options!
    host = ALTERNATE_HOSTS[paths_and_options.first] || HOST
    url = "#{host}/#{VERSION}/#{paths_and_options.map { |path_elem| CGI.escape path_elem.to_s }.join('/')}"
    url.gsub! '+', '%20' # dropbox doesn't really like plusses
    url << "?#{params.map { |k,v| CGI.escape(k.to_s) + "=" + CGI.escape(v.to_s) }.join('&')}" unless params.empty?
    return url
  end

  def self.check_path(path) # :nodoc:
    raise ArgumentError, "Backslashes are not allowed in Dropbox paths" if path.include?('\\')
    raise ArgumentError, "Dropbox paths are limited to 256 characters in length" if path.size > 256
    return path
  end
end
