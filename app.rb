require "sinatra"
require "sinatra/namespace"
require_relative 'models.rb'
require_relative "api_authentication.rb"
require "json"
require 'fog'
require 'csv'
require 'httparty'
def upload_image(image)
	if image && image[:tempfile] && image[:filename]
		begin
			token = "Bearer eyJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjozNH0.oPkAYlNIDjyayO7DSRO9mYV4sEbSLeUWmj4g0jUx0iI"
			file = image[:tempfile]
			response = HTTParty.post("http://nameless-forest-80107.herokuapp.com/api/images", body: { image: file },  :headers => { "Authorization" => token} )
			data = JSON.parse(response.body) 

			return data["url"]
		rescue => e
			puts e.message
			return nil
		end
	else
		return nil
	end
end

connection = Fog::Storage.new({
:provider                 => 'AWS',
:aws_access_key_id        => 'youraccesskey',
:aws_secret_access_key    => 'yoursecretaccesskey'
})

if ENV['DATABASE_URL']
	S3_BUCKET = "instagram"
else
	S3_BUCKET = "instagram-dev"
end

def placeholder
	halt 501, {message: "Not Implemented"}.to_json
end

if !User.first(email: "student@student.com")
	u = User.new
	u.email = "student@student.com"
	u.password = "student"
	u.bio = "Student"
	u.profile_image_url = "https://via.placeholder.com/1080.jpg"
	u.save
end

namespace '/api/v1' do
	before do
		content_type 'application/json'
	end

	#ACCOUNT MAINTENANCE

	#returns JSON representing the currently logged in user
	get "/my_account" do
		api_authenticate!
		halt 200, current_user.to_json(exclude: [:password, :role_id])
	end


	#let people update their bio
	patch "/my_account" do
			api_authenticate!
			if params["bio"]
			current_user.bio = params["bio"]
			current_user.save
			halt 200, current_user.to_json(exclude: [:password, :role_id])
			else
				halt 404, current_user.to_json(exclude: [:password, :role_id])
			end
			   
	end

	#let people update their profile image
	patch "/my_account/profile_image" do
		api_authenticate!
		if params["image"]
			url = upload_image(params["image"])
			current_user.profile_image_url = url
			current_user.save
			halt 200, current_user.to_json(exclude: [:password, :role_id])
		else
			halt 422, [message: "Missing image" ].to_json
		end
	end 

	#returns JSON representing all the posts by the current user
	get "/my_posts" do
		api_authenticate!
		posts = Post.all(user_id: current_user.id)
		halt 200, posts.to_json
	end

	#USERS

	#returns JSON representing the user with the given id
	#returns 404 if user not found
	get "/users/:id" do
	api_authenticate!
	u = User.get(params["id"])
	if u != nil
		halt 200, u.to_json(exclude: [:password, :role_id])
	else
		halt 404,{message: "User not found"}.to_json
	end
end

	#returns JSON representing all the posts by the user with the given id
	#returns 404 if user not found
	get "/users/:user_id/posts" do
		api_authenticate!
		u = User.get(params["id"])
		if u != nil
			halt 200, u.to_json(exclude: [:password, :role_id])
		else
			halt 404,{message: "User not found"}.to_json
		end
	end

	# POSTS

	#returns JSON representing all the posts in the database
	get "/posts" do
		api_authenticate!
		posts = Post.all
		halt 200, posts.to_json
	end

	#returns JSON representing the post with the given id
	#returns 404 if post not found
	get "/posts/:id" do
		api_authenticate!
		p = Post.get(params["id"])
		if p != nil
			halt 200, p.to_json
		else
			halt 404,{Mesagge: "Post not found"}.to_json
		end
	end

	#adds a new post to the database
	#must accept "caption" and "image" parameters
	post "/posts" do
		api_authenticate!
		if params["image"] && params["caption"]
			url = upload_image(params["image"])
			if url != nil
				p = Post.new
				p.caption = params["caption"]
				p.image_url = url
				p. user_id = current_user.id
				p.save
				halt 200, p.to_json
			else
				halt 422, [message: "Unable to upload image"].to_json
			end		
		else
			halt 422, {message: "Missing caption or image"}.to_json
		end
	end 

#updates the post with the given ID
    #only allow updating the caption, not the image
    patch "/posts/:id" do
        api_authenticate!
        p = Post.get(params["id"])

        if p != nil
            p.caption = params["caption"]
            p.save
            halt 200, p.to_json 
        else
            halt 404, {message: "Post not found"}.to_json
        end
    end

    #deletes the post with the given ID
    #returns 404 if post not found
    delete "/posts/:id" do
        api_authenticate!
        p = Post.get(params["id"])
        if p != nil && p.user_id == current_user.id
            p.destroy
            halt 200, {message: "Post deleted"}.to_json
        else
            return 401, {message: "Post not found"}.to_json
        end 
    end

    #COMMENTS

    #returns JSON representing all the comments
    #for the post with the given ID
    #returns 404 if post not found
    get "/posts/:id/comments" do
        api_authenticate!
        p = Post.get(params["id"]).comments
        if p != nil
            halt 200, p.to_json
        else
            return 404, {message: "Post not found"}.to_json
        end
    end

    #adds a comment to the post with the given ID
    #accepts "text" parameter
    #returns 404 if post not found
    post "/posts/:id/comments" do
        api_authenticate!
        p = Post.get(params["id"])
        
        if p != nil
            n = Comment.new
            n.user_id = current_user.id
            n.text = params["text"]
            n.post_id = params["id"]

            n.save

            halt 200, n.to_json
        else
            return 404, {message: "Post not found"}.to_json
        end
    end

    #updates the comment with the given ID
    #only allows updating "text" property
    #returns 404 if not found
    #returns 401 if comment does not belong to current user
    patch "/comments/:id" do
        api_authenticate!
        c = Comment.get(params["id"])

        if c == nil
            halt 404, {meaasge: "Comment not found"}.to_json
        end

        if c.user_id != current_user.id
            halt 401, {meaasge: "Comment does not belong to current user"}.to_json
        end

        c.text = params["text"]
        c.save
        halt 200, c.to_json

    end

    #deletes the comment with the given ID
    #returns 404 if not found
    #returns 401 if comment does not belong to current user
    delete "/comments/:id" do
        api_authenticate!
        c = Comment.get(params["id"])

        if c == nil
            halt 404, {meaasge: "Comment not found"}.to_json
        end

        if c.user_id != current_user.id
            halt 401, {meaasge: "Comment does not belong to current user"}.to_json
        end

        c.destroy

    end

    #LIKES
    
    #get the likes for the post with the given ID
    #returns 404 if post not found
    get "/posts/:id/likes" do
        api_authenticate!
        l = Post.get(params["id"])

        if l != nil
            halt 200, l.likes.to_json
        else
            halt 404, {message: "Post not found"}.to_json
        end
    end

    #adds a like to a post, if not already liked
    #returns 404 if post not found
    post "/posts/:id/likes" do
        api_authenticate!
        p = Post.get(params["id"])
        if p == nil
            halt 404, {message: "Post not found"}.to_json
        else 
            l = Like.new
            l.user_id = current_user.id
            l.post_id = params["id"]
            l.save
        end
	end

	#deletes a like from the post with
	#the given ID, if the like exists
	#returns 404 if not found
	#returns 401 if like does not belong to current user
	delete "/posts/:id/likes" do
		api_authenticate!
		 p = Post.get(params["id"])
		 if p != nil
			l = Like.first(post_id: p.id, user_id: current_user.id)
			if l != nil
				l.destroy
				halt 200, {message: "Succesfully unliked post"}.to_json
			else
				halt 200, {message: "Cannot unlike a post you dont like"}.to_json
			end
		else
			halt 404, {message: "Post not found"}.to_json
		end
	end
end