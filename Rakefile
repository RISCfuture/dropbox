require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "dropbox"
    gem.version = File.read("VERSION").chomp.strip
    gem.summary = %Q{Ruby Dropbox interface}
    gem.description = %Q{An easy-to-use interface to the RESTful Dropbox API.}
    gem.email = "dropbox@timothymorgan.info"
    gem.homepage = "http://github.com/RISCfuture/dropbox"
    gem.authors = ["Tim Morgan"]

    gem.files += FileList["lib/dropbox/*.rb"]
    gem.add_development_dependency "rspec", ">= 1.2.9"
    gem.add_runtime_dependency "oauth", ">= 0.3.6"
    gem.add_runtime_dependency "json", ">= 1.2.0"

    gem.rubyforge_project = "dropbox"
  end
  Jeweler::GemcutterTasks.new
  Jeweler::RubyforgeTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :spec => :check_dependencies

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION').chomp.strip : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "Dropbox API Client #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
