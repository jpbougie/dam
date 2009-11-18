require File.dirname(__FILE__) + '/test_helper'

Dam.activity :comment do
  action :post
  author { { :name => params[:author] } }
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

context "accept a complex object" do
  setup do
    Dam::stream :only_from_bob do
      accepts :author => { :name => "bob" }
    end
  end
  
  topic.kind_of(Dam::Stream)
  asserts("accepts a valid activity") { topic.matches? Dam::Activity[:comment].apply({:author => "bob"})}
  asserts("rejects an activity with a different value") { !topic.matches? Dam::Activity[:comment].apply({:author => "not bob"})}
  asserts("reject an activity which doesn't have the attribute") { !topic.matches? Dam::Activity[:edit].apply }
end