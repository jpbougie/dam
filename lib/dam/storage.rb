require 'redis'

module Dam
  class Storage
    def Storage.register(name, engine)
      @engines ||= {}
      @engines[name] = engine
    end
    
    def self.database
      return @database if instance_variable_defined? '@database'
    end
    
    def self.database=(database)
      @database = database
    end
    
    def self.insert(stream, activity)
      key = stream.name
      
      self.database.push_head("stream:#{key}", activity.to_db)
      self.database.ltrim("stream:#{key}", 0, (stream.limit || 10) - 1)
      
    end
    
    def self.get(stream_name)
      self.database.list_range("stream:#{stream_name}", 0, -1).collect {|data| Dam::Activity.from_db(data) }
    end
    
    private 
    def Storage.lookup(name)
      @engines ||= {}
      @engines[name]
    end
  end
end