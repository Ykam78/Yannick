# The "New" Instagram

## Introduction

The goal in this assignment is to learn how to make a modern social network using backend development skills. The goal is walk the student through the process of incrementally developing each feature and ending comments and likes. Students will learn how to make simple API application features protected by authentication (signing in) and authorization (only seeing what you're allowed to).



**View the end point documentation here:** https://documenter.getpostman.com/view/7032600/S17rw96w



## Prerequisites

1. Install Ruby via [RailsInstaller](http://railsinstaller.org/en) *(install latest version)*

2. Clone project

3. Navigate to directory in command line

4. Install required gems: `bundle install --without production`

5. Run server with: `bundle exec ruby app.rb`


## Running the Application
1.  'bundle exec ruby app.rb' 
   



## What is in the box
1. User model
2. API Authentication


## Protecting pages from non-signed in users

### api_authenticate!

I have created a helper method`api_authenticate!` which, when called, will return status `401 Unauthorized` to users who did not pass a valid token. This will help you protect routes that should only be accessed by signed in users.

To define a URL in which the person must pass a token to access, use the `api_authenticate!` method.

For example:

```ruby
get "/hello_world" do 
  api_authenticate!
  halt 200, {message: "Hello World"}.to_json
end
```



### Who is Signed in?

To get information about the current signed in user, use the `current_user` method which returns the user object of the current signed in user or `nil` if no one is signed in.



In code:

```ruby
get '/say_hello' do
    api_authenticate!
	if current_user
      return "Hello #{current_user.email}!"
    else
      return "Hello World!"
    end
end
```


## Part 0 - Getting Started

Part 0 should work out of the box. These tests make sure that you have all the prerequisites to begin the assignment. The tests are related to API authentication, which is provided for you.

* Run the Tests with `bundle exec rspec spec/part0_spec.rb`



## Part 1 - Modeling the Data

For part 1 your job is to add to the Post, Comment, and Like classes such that they have all the properties we need.

* Run tests with: `bundle exec rspec spec/part1_spec.rb`



#### Post

- should have property **id**, type **Serial**
- should have property **caption**, type **Text**
- should have property **image_url**, type **Text**
- should have property **created_at**, type **DateTime** 
- should have property **user_id**, type **Integer**



#### Comment

* should have property **id**, type **Serial**
* should have property **user_id**, type **Integer**
* should have property **post_id**, type **Integer**
* should have property **text**, type **Text**
* should have property **created_at**, type **DateTime** 



#### Like

- should have property **id**, type **Serial**
- should have property **user_id**, type **Integer**
- should have property **post_id**, type **Integer**
- should have property **created_at**, type **DateTime** 



## Part 2 - Accounts / Users

Make the API endpoints for managing the logged in user's account. Also provide the ability to lookup a user by ID and retrieve their info. 

**IMPORTANT: The JSON for users should not include "password" or "role_id"**

*Run tests with: `bundle exec rspec spec/part2_spec.rb`



**GET /api/v1/my_account**

returns JSON representing the currently logged in user



**GET /api/v1/users/:id**

returns JSON representing the user with the given id

returns 404 if user not found



**PATCH /api/v1/my_account**

Required Parameters: bio

let people update their bio



**PATCH /api/v1/my_account/profile_image**

Required Parameters: image

let people update their profile image



## Part 3 - Posts

The heart of the application. Allow users to create, read, update, destroy posts in the system.

* Run tests with: `bundle exec rspec spec/part3_spec.rb`



**GET /api/v1/posts**

returns JSON representing all the posts in the database



**GET /api/v1/posts/:id**

returns JSON representing the user with the given id

returns 404 if user not found



**GET /api/v1/my_posts**

returns JSON representing all the posts by the current user

returns 404 if user not found



**POST /api/v1/posts**

Required Parameters: "caption", "image"

adds a new post to the database



**DELETE /api/v1/posts/:id**

deletes the post with the given ID

returns 404 if post not found



## Part 4 - Likes

Interactivity! Add the ability to view and manage likes.

* Run tests with: `bundle exec rspec spec/part4_spec.rb`



**GET /api/v1/posts/:id/likes**

get the likes for the post with the given ID

returns 404 if post not found



**POST /api/v1/posts/:id/likes**

adds a like to a post, if not already liked

returns 404 if post not found



**DELETE /api/v1/posts/:id/likes**

deletes a like from the post with the given ID, if the like exists

returns 404 if not found

returns 401 if like does not belong to current user



## Part 5 - Comments

Let the trolling commence. Add the ability for users to comment on each other's posts.

* Run tests with: `bundle exec rspec spec/part5_spec.rb`



**GET /api/v1/posts/:id/comments**

returns JSON representing all the comments for the post with the given ID

returns 404 if post not found



**POST /api/v1/posts/:id/comments**

Required Parameter: "text"

adds a comment to the post with the given ID

returns 404 if post not found



**PATCH /api/v1/comments/:id**

Required Parameter: "text"

Updates the comment with the given ID

returns 404 if not found

returns 401 if comment does not belong to current user



**DELETE /api/v1/comments/:id**

Deletes the comment with the given ID

returns 404 if not found

returns 401 if comment does not belong to current user



## Deploying to Heroku

### Deployment Instructions

1. Add all your changes on git and make a commit
2. Create a Heroku server: `heroku create`
3. Create a database for your server: `heroku addons:create heroku-postgresql:hobby-dev`
4. Push the code to Heroku: `git push heroku master`
5. I preconfigured the necessary files for this to work.
6. Verify all is working and submit your links (github and heroku) to me.