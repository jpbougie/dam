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
      @attributes[params[:name]] = params[:value] || params[:block]
      self
    end
    
    def apply(params = {})
      context = Context.new(params)
      evaluated_attributes = {}
      @attributes.each_pair do |attribute, value| 
        evaluated_attributes[attribute] = if value.respond_to? :call
          context.instance_eval(&value)
        else
          value
        end
      end
      
      Activity.new(evaluated_attributes)
    end
  end
  
  class Activity
    
    def self.[](name)
      Dam::ActivityType.lookup(name)
    end
    
    attr_accessor :id, :attributes
    def initialize(params = {})
      @attributes = params
    end
    
    def submit!
      Dam.push(self)
    end
    
    private
    
    def method_missing(meth, *args, &block)
      if @attributes.has_key? meth
        @attributes[meth]
      else
        super
      end
    end
    
    def self.key(*parts)
      "#{name}:v1:#{parts.join(":")}"
    end
  end
end
