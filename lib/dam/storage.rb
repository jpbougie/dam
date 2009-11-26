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
    
    def self.insert(activity, streams)
      id = self.save(activity)
      
      streams.each do |stream|
        self.database.push_head("stream:#{stream.name}", "activity:#{id}")
        self.database.ltrim("stream:#{stream.name}", 0, (stream.limit || 10) - 1)
      end
    end
    
    def self.get(stream_name)
      self.database.mget(self.database.list_range("stream:#{stream_name}", 0, -1))
    end
    
    def self.head(stream_name)
      self.database[self.database.list_index("stream:#{stream_name}", 0)]
    end
    
    def self.keys(spec='*')
      self.database.keys("stream:#{spec}").collect {|key| key.sub(/^stream:/, '')}
    end
    
    def self.save activity
      id = self.generate_unique_id!
      
      self.database["activity:#{id}"] = activity.to_json
      
      id
    end
    
    private 
    
    def self.generate_unique_id!
      database.incr("dam:activity:id")
    end
    
    def Storage.lookup(name)
      @engines ||= {}
      @engines[name]
    end
  end
end