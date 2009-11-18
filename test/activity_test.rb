require File.dirname(__FILE__) + '/test_helper'

context "a new activity type" do
  setup do
    Dam::activity :comment_posted do
      subject :user do "Some Author"; end
      action :post
      object :comment do
        {:id => params[:comment]}
      end
      
      object :project do
        {:id => params[:project], :some_other_property => true }
      end
      published { Date.today }
      text { "a comment has been posted" }
    end
  end
  
  topic.kind_of(Dam::ActivityType)
  
  asserts("is registered") { topic }.equals(Dam::ActivityType.lookup(:comment_posted))
  asserts("has a subject of class Subject") { topic.subject }.kind_of(Dam::Subject)
  asserts("has a subject with a proc") { topic.subject.block }.kind_of(Proc)
  asserts("has a subject with a type") { topic.subject.type }.kind_of(Symbol)
  
  asserts("has an action of class Action") { topic.action }.kind_of(Dam::Action)
  asserts("has an action without a proc") { topic.action.block }.nil
  asserts("has an action with a type") { topic.action.type }.kind_of(Symbol)
  
  asserts("has many objects") { topic.object.size }.equals(2)
  asserts("has 2 objects with classes of Obj") { topic.object.collect {|obj| obj.class } }.equals([Dam::Obj, Dam::Obj])
  asserts("has 2 objects with types") { topic.object.collect {|obj| obj.type.class } }.equals([Symbol, Symbol])
  asserts("has 2 objects with blocks") { topic.object.collect {|obj| obj.block.class } }.equals([Proc, Proc])
  
  asserts("has a published date proc") { topic.published }.kind_of(Proc)
  
  asserts("has a text proc") { topic.text }.kind_of(Proc)
  
  context "can be instantiated" do
    setup do
      topic.apply({:comment => "ab3d", :project => "xyz" })
    end
    
    topic.kind_of(Dam::Activity)
    
    asserts("the subject has been evaluated") { topic.subject }.equals({:type => :user, :value => "Some Author"})
    asserts("the action has been evaluated") { topic.action }.equals(:post)
    asserts("the published date has been evaluated") { topic.published }.kind_of(Date)
    asserts("the objects have all been evaluated") { topic.object.size }.equals(2)
    asserts("the first object is a comment") { topic.object[0] }.equals({:type => :comment, :id => "ab3d"})
    asserts("the second object is a project") { topic.object[1] }.equals({:type => :project, :id => "xyz", :some_other_property => true})
  end
end