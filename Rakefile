$LOAD_PATH.unshift "lib"


begin
  require 'jeweler'
  require 'resque/version'
 
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "dam"
    gemspec.summary = "An activity stream framework for Ruby"
    gemspec.description = ""
    gemspec.email = "jp.bougie@gmail.com"
    gemspec.homepage = "http://github.com/defunkt/resque"
    gemspec.authors = ["Jean-Philippe Bougie"]
    gemspec.version = Dam::Version
 
    gemspec.add_dependency "redis"
    gemspec.add_dependency "redis-namespace"
    gemspec.add_development_dependency "jeweler"
  end
rescue LoadError
  puts "Jeweler not available. Install it with: "
  puts "gem install jeweler"
end