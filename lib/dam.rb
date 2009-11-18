require 'dam/activity'
require 'dam/storage'
require 'dam/stream'


module Dam
  
  def self.push(activity)
    Dam::Stream.all.select {|stream| stream.matches? activity }.each do |stream|
      Dam::Storage.insert(stream, activity)
    end
  end
  
  def self.post(type, params = {})
    act = Activity.new(Dam::ActivityType.lookup(type.to_sym), params)

    act.submit!
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