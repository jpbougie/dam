module Dam
  class TypedBlock
    attr_accessor :type, :block
    
    def initialize(_type = nil, _block = nil)
      self.type = _type
      self.block = _block
    end
  end
  
  class Subject < TypedBlock; end
  class Action  < TypedBlock; end
  class Obj  < TypedBlock; end
  
  class ActivityType
    
    
    def self.register(type, act)
      @activity_types ||= {}

      @activity_types[type] = act
    end

    def self.lookup(type)
      @activity_types ||= {}

      @activity_types[type]
    end
    
    def initialize(name, *args, &block)
      
      @name = name
      @subject = Subject.new
      @action = Action.new
      @objects = []
      @published = nil
      @text = Proc.new { "" }
      
      if block_given?
        instance_eval(&block)
      end
    end
    
    def name
      @name
    end
    
    def subject=(val)
      @subject = val
    end
    
    def subject(val=nil, &block)
      val ? self.subject = Subject.new(val, block) : @subject
    end
    
    def action=(val)
      @action = val
    end
    
    def action(val = nil, &block)
      val ? self.action = Action.new(val, block) : @action
    end
    
    def object(val = nil, &block)
      val ? @objects.push(Obj.new(val, block)) : @objects
    end
    
    def published(&block)
      block_given? ? @published = block : @published
    end
    
    def text(&block)
      block_given? ? @text = block : @text
    end
    
    def apply(params)
      holder = Struct.new(:params).new
      holder.params = params
      attributes = {}
      [:subject, :action, :published, :text].each do |attribute| 
        result = eval_attribute(send(attribute), holder)
        attributes[attribute] = result
      end
      
      # a special case for object's, as it can be multiple
      attributes[:object] = object.collect {|attribute| eval_attribute(attribute, holder) }
      
      
      Activity.new(attributes)
    end
    
    private
    
    def eval_attribute(attribute, context)    
      if attribute.is_a? TypedBlock
        if !attribute.block.nil?
          result = context.instance_eval(&(attribute.block))
          
          if result.respond_to? :merge
            result.merge({:type => attribute.type})
          else
            {:type => attribute.type, :value => result}
          end
        else
          attribute.type
        end
      else
        attribute.respond_to?(:call) ? context.instance_eval(&attribute) : attribute
      end
    end
  end
  
  class Activity
    attr_accessor :id
    attr_accessor :subject, :action, :object, :published, :text, :type
    def initialize(params = {})
      self.attributes = params
    end
    
    def submit!
      Dam.push(self)
    end
    
    def attributes=(attrs)
      attrs.each_pair do |key, value|
        send("#{key}=", value)
      end
    end
    
    private
    
    def self.key(*parts)
      "#{name}:v1:#{parts.join(":")}"
    end
    
    
  end
  
end

