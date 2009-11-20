$LOAD_PATH.unshift File.dirname(__FILE__) + '/lib'

task :default => :test

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/*_test.rb'
  test.verbose = false
end


begin
  require 'jeweler'
  require 'dam/version'
 
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "dam"
    gemspec.summary = "An activity stream framework for Ruby"
    gemspec.description = ""
    gemspec.email = "jp.bougie@gmail.com"
    gemspec.homepage = "http://github.com/jpbougie/dam"
    gemspec.authors = ["Jean-Philippe Bougie"]
    gemspec.version = Dam::Version
 
    gemspec.add_dependency "redis"
    gemspec.add_dependency "yajl-ruby"
    gemspec.add_development_dependency "jeweler"
    gemspec.add_development_dependency "riot"
  end
  
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler not available. Install it with: "
  puts "gem install jeweler"
end