require File.dirname(__FILE__) + '/test_helper'


# Define some activities to be used in the tests
Dam.activity :comment do
  action "post"
  author { { "name" => params[:author] } }
end

Dam.activity :edit do
  action :edit
end


context "a stream which filters the latest 25 activities" do
  setup do
    Dam::stream :all do
      limit 25
      accepts :all
    end
  end
  
  topic.kind_of(Dam::Stream)
  topic.equals(Dam::Stream[:all])
  asserts("has one filter") { topic.filters.size }.equals(1)
  asserts("has a limit of 25") { topic.limit }.equals(25)
  
  asserts("accepts an activity") { topic.matches? Dam::Activity[:comment].apply({:author => "test"})}
end

context "a stream which only accepts edits" do
  setup do
    Dam::stream :edit_actions do
      accepts :action => :edit
    end
  end
  
  topic.kind_of(Dam::Stream)
  asserts("rejects a post action") { !topic.matches? Dam::Activity[:comment].apply({:author => "test"})}
  asserts("accepts an edit") { topic.matches? Dam::Activity[:edit].apply}
end

context "a stream with a complex object filter" do
  setup do
    Dam::stream :only_from_bob do
      accepts :author => { "name" => "bob" }
    end
  end
  
  topic.kind_of(Dam::Stream)
  asserts("accepts a valid activity") { topic.matches? Dam::Activity[:comment].apply({:author => "bob"})}
  asserts("rejects an activity with a different value") { !topic.matches? Dam::Activity[:comment].apply({:author => "not bob"})}
  asserts("reject an activity which doesn't have the attribute") { !topic.matches? Dam::Activity[:edit].apply }
end

context "post an activity" do
  setup do
    Dam::Storage.clear!
    Dam.stream :all do
      accepts :all
    end
    
    act = Dam::Activity[:comment].apply(:author => "bob")
    act.post!
    act
  end
  
  asserts("the stream has one element") { Dam::Stream[:all].all.size }.equals(1)
  topic.equals(Dam::Stream[:all].first)
end

context "post multiple activities" do
  setup do
    Dam::Storage.clear!
    Dam.stream :only_2 do
      accepts :all
      limit 2
    end
    3.times {|i| Dam::Activity[:comment].apply(:author => "bob_#{i}").post! }
  end
  
  asserts("the stream has been limited to 2 elements") { Dam::Stream[:only_2].all.size }.equals(2)
  asserts("the first one is the last to be entered") { Dam::Stream[:only_2].first.author }.equals({"name" => "bob_2"})
end


context "a parameterized stream" do
  setup do
    Dam::Storage.clear!
    Dam.stream "comments/:author" do
      accepts :author => { "name" => params[:author] }
    end
  end
  
  topic.kind_of(Dam::TemplatedStream)
  asserts("has no actual instances at first") { topic.instances.size }.equals(0)
  
  context "with an instance" do
    setup do
      Dam::Stream["comments/bob"].instantiate!
    end
    
    topic.kind_of(Dam::Stream)
    asserts("matches a valid activity") { topic.matches? Dam::Activity[:comment].apply(:author => "bob") }
  end
end

context "a stream with a proc condition" do
  setup do
    Dam::Storage.clear!
    Dam.stream :with_a_proc do
      accepts :author => { "name" => Proc.new {|name| name.reverse == name} }
    end
  end
  
  topic.kind_of(Dam::Stream)
  asserts("matches a valid activity") { topic.matches? Dam::Activity[:comment].apply(:author => "abcba") }
  asserts("rejects an invalid activity") { !topic.matches? Dam::Activity[:comment].apply(:author => "not valid") }
end