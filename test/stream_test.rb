require File.dirname(__FILE__) + '/test_helper'

context "a stream which filters the latest 25 activities" do
  setup do
    Dam::stream :all do
      limit 25
      accepts :all
    end
  end
  
  topic.kind_of(Dam::Stream)
  asserts("has one filter") { topic.filters.size }.equals(1)
  asserts("has a limit of 25") { topic.limit }.equals(25)
end