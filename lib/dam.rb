require 'dam/activity'
require 'dam/storage'
require 'dam/stream'

require 'yajl'

module Dam
  
  def self.push(activity)
    Dam::Storage.insert(activity, Dam::Stream.all.select {|stream| stream.matches? activity })
  end
  
  def self.post(type, params = {})
    act = Dam::ActivityType.lookup(type.to_sym).apply(params)

    act.post!
    
    act
  end
  
  def self.activity(name, &block)
    act = Dam::ActivityType.new(name, &block)
    Dam::ActivityType.register(name, act)
    act
  end
  
  def self.stream(name, &block)
    definition = StreamDefinition.new
    definition.instance_eval(&block)
    
    stream = if Stream.has_placeholder? name
      TemplatedStream.new(name, definition)
    else
      Stream.new(name, definition)
    end
    Dam::Stream.register(name, stream)
  end
  
end