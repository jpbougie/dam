module Dam
  
  class Stream
    
    class ParamsProxy
      attr_reader :key
      def initialize(key)
        @key = key
      end
      
      def self.[] key
        ParamsProxy.new(key)
      end
    end
    
    def Stream.lookup(name)
      @streams ||= {}
      @streams[name]
    end
    
    def Stream.register(name, stream)
      @streams ||= {}
      @streams[name] = stream
    end
    
    def Stream.all
      instantiated
    end
    
    def Stream.instantiate(name)
      Dam::Storage.database.push_head("stream:#{name}", 1)
      Dam::Storage.database.pop_head("stream:#{name}")
    end
    
    def Stream.instantiated
      streams = []
      streams += @streams.values
      @streams.each_pair do |key, value|
        elems = Dam::Storage.database.keys("stream:" + value.keyspec)
        elems.each {|elem| streams << value.instantiate(elem) }
      end
      
      streams.reject {|s| s.abstract? }
    end
    
    attr_reader :name
    
    def initialize(_name, params = {}, &block)
      @regexp = %r{:[^:@/-]+}
      @params = params
      @name = @template_name =  _name
      @filters = []
      @limit = 10
      @block = block
      @template_name = nil
      instance_eval(&block)
      if params.length
        params.each_pair do |pattern, replacement|
          @name = @name.gsub(":#{pattern}", replacement)
        end
      end
    end
    
    def abstract?
      keyspec.include?("*") && @params.length == 0
    end
    
    def template_name
      @template_name
    end
    
    def keyspec
      # returns the key spec that should be looked up. Uses Redis' key spec patterns
      @patterns = []
      
      name.gsub(@regexp) do |match|
        @patterns << match[1..-1].to_sym
        '*'
      end
    end
    
    def patterns
      self.keyspec
      
      @patterns
    end
    
    def accepts(args = {})
      @filters << args
    end
    
    def params
      ParamsProxy
    end
    
    def limit(num= nil)
      num ? @limit = num : @limit
    end

    def matches? activity
      @filters.any? do |filter|
        return true if filter == :all
        
        filter.any? do |key, value|
          if key == :object
            activity.object.any? {|hash| attr_match(value, hash)}
          else
            attr_match(value, activity.send(key))
          end
        end
      end
    end
    
    def instantiate(val)
      Stream.new(@name, Hash[*self.patterns.zip(val.match(to_regexp).captures).flatten], &@block)
    end
    
    private
      def attr_match(condition, element)
        if condition.respond_to? :each_pair
          condition.all? do |key, value|
            (element.respond_to?(key) ? element.send(key) : element[key]) == (value.is_a?(ParamsProxy) ? @params[value.key] : value)
          end
        else
          condition == (element.is_a?(ParamsProxy) ? @params[element.key] : element)
        end
      end
      
      def to_regexp
        @name.gsub(@regexp, "([^/:-]+)")
      end
  end
end

def stream(name, &block)
  Dam::Stream.register(name, Dam::Stream.new(name, &block))
end