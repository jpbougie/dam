require 'rubygems'

require 'riot'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require 'dam'

DATABASE = 15 # change this if you already use database #15 for something else

Dam::Storage.database = Redis.new(:db => DATABASE) # change this to your running redis server

module Dam
  class Storage
    def self.clear!
      @database.keys("*").each {|k| @database.delete k}
    end
  end
end