require 'rake'
begin
  require 'bundler'
rescue LoadError
  puts "Bundler is not installed; install with `gem install bundler`."
  exit 1
end

Bundler.require :default

Jeweler::Tasks.new do |gem|
  gem.name = "dropbox"
  gem.summary = %Q{Ruby client library for the official Dropbox API}
  gem.description = %Q{An easy-to-use client library for the official Dropbox API.}
  gem.email = "dropbox@timothymorgan.info"
  gem.homepage = "http://github.com/RISCfuture/dropbox"
  gem.authors = [ "Tim Morgan" ]
  gem.add_dependency 'oauth', '>= 0.3.6'
  gem.add_dependency 'json', '>= 1.2.0'
  gem.add_dependency 'multipart-post', '>= 1.0'
  gem.add_dependency 'mechanize', '>= 1.0.0'
end
Jeweler::GemcutterTasks.new

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new

require 'rake/rdoctask'
Rake::RDocTask.new(:doc) do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION').chomp.strip : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "Dropbox API Client #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('LICENSE')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

task(default: :spec)
