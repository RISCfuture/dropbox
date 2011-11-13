require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  gem.name = "dropbox"
  gem.summary = %Q{Ruby client library for the official Dropbox API}
  gem.description = %Q{An easy-to-use client library for the official Dropbox API.}
  gem.email = "dropbox@timothymorgan.info"
  gem.homepage = "http://github.com/RISCfuture/dropbox"
  gem.authors = [ "Tim Morgan" ]
  gem.files = %w( lib/**/* examples ChangeLog dropbox.gemspec LICENSE README.rdoc )
end
Jeweler::RubygemsDotOrgTasks.new

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new

require 'rdoc/task'
Rake::RDocTask.new(:doc) do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION').chomp.strip : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "Dropbox API Client #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('LICENSE')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

task :default => :spec
