module Dam
  
  
  PLACEHOLDER_PATTERN = %r{:[^:@/-]+}
  
  # provides the basis of the DSL to define a stream
  class StreamDefinition
    def initialize
      @filters = []
      @limit = 10
    end
    
    def limit(amount = nil)
      amount.nil? ? @amount : @amount = amount
    end
    
    def filters
      @filters
    end
    
    def accepts(args = {})
      @filters << args
    end
    
    def params
      ParamsProxy
    end
  end
  
  
  # a class that will allow us to note which param has been used from the placeholders
  class ParamsProxy
    attr_reader :key
    def initialize(key)
      @key = key
    end
    
    def self.[] key
      ParamsProxy.new(key)
    end
  end
  
  # a templated stream is one which contains placeholders, and thus will only be defined through his instances
  class TemplatedStream
    attr_reader :name
    
    def initialize(name, definition)
      @name = name
      @definition = definition
      
      extract_placeholders!
      make_glob_pattern!
      make_regexp!
    end
    
    def apply(params)
      Stream.new(replace_placeholders(params), definition, :params => params)
    end
    
    def instances
      elems = Dam::Storage.database.keys("stream:" + @glob_pattern)
      elems.each {|elem| streams << apply(elem) }
    end
    
    private
    
    def replace_placeholders(params)
      name = @name
      params.each_pair do |key, value|
        name = name.gsub(":#{key}", value.to_s)
      end
      
      name
    end
    
    def extract_placeholders!
      @placeholders = @name.match(PLACEHOLDER_PATTERN).captures
    end
    
    def make_glob_pattern!
      @glob_pattern = @placeholders.inject(@name) do |name, placeholder|
        name.sub(placeholder, "*")
      end
    end
    
    def make_regexp!
      @regexp = @placeholders.inject(@name) do |name, placeholder|
        name.sub(placeholder, "([^/:-]+)")
      end
    end
  end
  
  class Stream
    def Stream.lookup(name)
      @streams ||= {}
      @streams[name]
    end
    
    def Stream.[](name)
      lookup(name)
    end
    
    def Stream.register(name, stream)
      @streams ||= {}
      @streams[name] = stream
      stream
    end
    
    def Stream.has_placeholder? string
      string =~ PLACEHOLDER_PATTERN
    end
    
    
    attr_reader :name
        
    def initialize(name, definition, params = {})
      @name = name
      @definition = definition
      @params = params.delete(:params)
    end
    
    def limit
      @definition.limit
    end
    
    def filters
      @definition.filters
    end

    def matches? activity
      filters.any? do |filter|
        return true if filter == :all
        
        filter.any? do |key, value|
          attr_match(value, activity.attributes[key])
        end
      end
    end
    
    def instantiate(val)
      Stream.new(@name, Hash[*self.patterns.zip(val.match(to_regexp).captures).flatten], &@block)
    end
    
    private
    
    def ensure_exists!
      if Dam::Storage.database.keys["stream:#{name}"].size == 0
        Dam::Storage.database.push_head("stream:#{name}", 1)
        Dam::Storage.database.pop_head("stream:#{name}")
      end
    end
  
    def attr_match(condition, element)
      # match a nil element with a nil condition
      return condition.nil? if element.nil?
      
      if condition.respond_to? :each_pair
        condition.all? do |key, value|
          (element.respond_to?(key) ? element.send(key) : element[key]) == (value.is_a?(ParamsProxy) ? @params[value.key] : value)
        end
      else
        condition == (element.is_a?(ParamsProxy) ? @params[element.key] : element)
      end
    end
  end
end