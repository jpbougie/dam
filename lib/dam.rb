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
  
  def activity(name, &block)
    Dam::ActivityType.register(name, Dam::ActivityType.new(name, &block))
  end
  
end