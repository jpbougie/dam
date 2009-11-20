require File.dirname(__FILE__) + '/test_helper'

context "a new activity type" do
  setup do
    Dam::activity :comment_posted do
      author "Some Author"
      action :post
      
      comment do
        {:id => params[:comment]}
      end
      
      project do
        {:id => params[:project], :some_other_property => true }
      end
      published { Date.today }
      text { "a comment has been posted" }
    end
  end
  
  topic.kind_of(Dam::ActivityType)
  
  asserts("is registered") { topic }.equals(Dam::ActivityType.lookup(:comment_posted))
  asserts("has a name") { topic.name }.equals(:comment_posted)
  
  asserts("has a static author") { topic.attributes["author"] }.equals("Some Author")
  asserts("has a static action") { topic.attributes["action"] }.equals(:post)
  
  asserts("has a comment proc") { topic.attributes["comment"] }.kind_of(Proc)
  asserts("has a project proc") { topic.attributes["project"] }.kind_of(Proc)
  
  asserts("has a published proc") { topic.attributes["published"] }.kind_of(Proc)
  asserts("has a text proc") { topic.attributes["text"] }.kind_of(Proc)
  
  context "can be instantiated" do
    setup do
      topic.apply({:comment => "ab3d", :project => "xyz" })
    end
    
    topic.kind_of(Dam::Activity)
    
    asserts("the author has been evaluated") { topic.author }.equals("Some Author")
    asserts("the action has been evaluated") { topic.action }.equals(:post)
    asserts("the published date has been evaluated") { topic.published }.kind_of(Date)
    asserts("the comment has been evaluated") { topic.comment }.equals({:id => "ab3d"})
    asserts("the project has been evaluated") { topic.project }.equals({:id => "xyz", :some_other_property => true})
    asserts("the text has been evaluated") { topic.text }.equals("a comment has been posted")
  end
end


context "an activity without params" do
  setup do
    Dam.activity :no_params do
      action :post
      author "bob"
      some_param 123
    end
  end
   topic.kind_of(Dam::ActivityType)
   asserts("can be applied without params") { topic.apply }.kind_of(Dam::Activity)
end