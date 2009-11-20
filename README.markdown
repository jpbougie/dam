Dam
===

A ruby framework for Activity Streams, using Redis as a backend

Assuming you have added gemcutter.org to your ruby gems sources, dam is easy to install using
  
    gem install dam

Using Dam
=========

You need to configure dam to connect to your current redis installation. To do that, put this line somewhere in your code
    Dam::Storage.database = Redis.new

First, define your activities. You can use any attributes you wish, and give blocks or static values, as long as they are serializable to json

    require 'dam'
    Dam.activity :comment_posted do
      author { "name" => params[:comment].user.name, "id" => params[:comment].user.id }
      published { params[:comment].created_at.to_s }
      comment { "id" => params[:comment].id, "excerpt" => params[:comment].excerpt }
      action "post"
    end
    
Then declare streams that will accepts these activities

    require 'dam'
    Dam.stream :activities_from_bob do
      limit 10
      accepts :action => "post", :author => {"name" => "bob"}
    end
  
Finally, just post your activities:
    Dam.post :comment_posted, :comment => my_comment
    
And access the stream's activities using:
    Dam::Stream[:activities_from_bob].all.each {|activity| puts activity.comment["excerpt"] }
    
Further possibilities
=====================

You can create _templated_ streams, that is, streams who first have to be instantiated to start receiving activities. To do this, use a route-like name, such as

    Dam.stream "project/:project" do
      limit 15
      accepts :project => {"id" => params[:project]}
    end

You can then instantiate these projects to start receiving events

    Dam::Stream["project/12345"].instantiate!
