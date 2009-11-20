module Dam
  
  private
  
  class TypeProxy
    instance_methods.each { |m| undef_method m unless m =~ /(^__|instance_eval)/ }
    
    def initialize(type)
      @type = type
    end
    
    def method_missing(meth, arg=nil, &block)
      
      # the attribute can either be a static value, or a block to be evaluated, not both
      raise ArgumentError unless (!arg.nil? ^ block_given?)
      
      if block_given?
        @type.add_attribute(:name => meth, :block => block)
      else
        @type.add_attribute(:name => meth, :value => arg)
      end
      
    end
  end
  
  class Context
    attr_reader :params
    def initialize(params); @params = params; end
  end
  
  public
  
  class ActivityType
    attr_accessor :attributes
    attr_reader :name

    # Class methods
    def self.register(type, act)
      @activity_types ||= {}
      @activity_types[type] = act
    
      act
    end

    def self.lookup(type)
      @activity_types ||= {}
      @activity_types[type]
    end

    # Instance methods
    def initialize(name, &block)
      @attributes = {}
      @name = name
      
      proxy = TypeProxy.new(self)
      
      proxy.instance_eval(&block)
    end
    
    def add_attribute(params = {})
      @attributes[params[:name].to_s] = params[:value] || params[:block]
      self
    end
    
    def apply(params = {})
      context = Context.new(params)
      evaluated_attributes = {}
      @attributes.each_pair do |attribute, value| 
        evaluated_attributes[attribute.to_s] = if value.respond_to? :call
          context.instance_eval(&value)
        else
          value
        end
      end
      
      Activity.new(self.name, evaluated_attributes)
    end
  end
  
  class Activity
    
    def self.[](name)
      Dam::ActivityType.lookup(name)
    end
    
    attr_accessor :attributes
    def initialize(type, params = {})
      @attributes = params
      @type = type
    end
    
    def ==(other)
      @type == other.instance_variable_get("@type") && attributes == other.attributes
    end
    
    def post!
      Dam.push(self)
    end
    
    def self.from_json json
      attributes = Yajl::Parser.parse(json)
      type = attributes.delete("_type").to_sym
      new(type, attributes)
    end
    
    def to_json
      Yajl::Encoder.encode(self.attributes.merge({:_type => @type}))
    end
    
    private
    
    def method_missing(meth, *args, &block)
      if @attributes.has_key? meth.to_s
        @attributes[meth.to_s]
      else
        super
      end
    end
  end
end
