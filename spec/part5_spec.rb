# spec/app_spec.rb
require File.expand_path '../spec_helper.rb', __FILE__
require 'jwt'

def has_status_200
	expect(last_response.status).to eq(200)
end

def has_status_404
	expect(last_response.status).to eq(404)
end

def has_status_unauthorized
	expect(last_response.status).to eq(401)
end

def has_status_unprocessable
	expect(last_response.status).to eq(422)
end

def has_status_created
	expect(last_response.status).to eq(201)
end

def is_valid_token?(encoded_token)
	begin
	JWT.decode encoded_token, "lasjdflajsdlfkjasldkfjalksdjflk", true, { algorithm: 'HS256' }
	return true
	rescue
	return false
	end
end

def get_user_id_from_token(encoded_token)
	begin
	decoded = JWT.decode encoded_token, "lasjdflajsdlfkjasldkfjalksdjflk", true, { algorithm: 'HS256' }
	return decoded[0]["user_id"]
	rescue
	return nil
	end
end

def contains_post_attributes(hash)
	expect(hash.key? "id").to eq(true)
	expect(hash.key? "caption").to eq(true)
	expect(hash.key? "image_url").to eq(true)
	expect(hash.key? "user_id").to eq(true)
	expect(hash.key? "created_at").to eq(true)
end

def json_hash_matches_object?(hash, post_obj)
	contains_post_attributes(hash)
	expect(hash["id"]).to eq(post_obj.id)
	expect(hash["caption"]).to eq(post_obj.caption)
	expect(hash["image_url"]).to eq(post_obj.image_url)
	expect(hash["user_id"]).to eq(post_obj.user_id)
end

describe "When not signed in, API" do
  before(:all) do 
  	@u = User.new
  	@u.email = "p1@p1.com"
  	@u.password = "p1"
  	@u.save

  	@u2 = User.new
  	@u2.email = "p2@p2.com"
  	@u2.password = "p2"
  	@u2.save

  	@p = Post.new
  	@p.caption = "Sample post"
  	@p.image_url = "https://via.placeholder.com/1080.jpg"
  	@p.user_id = @u.id
    @p.save
      
    @c = Comment.new
    @c.user_id = @u2.id
    @c.post_id = @p.id
    @c.text = "cool"
    @c.save

    @c2 = Comment.new
    @c2.user_id = @u.id
    @c2.post_id = @p.id
    @c2.text = "commenting on my own post!"
    @c2.save
    
  end

  it "should have two users in test database" do 
  	expect(User.all.count).to eq(2)
  end

  it "should not allow commenting on a post" do
    post "/api/v1/posts/#{@p.id}/comments?post_id=#{@p.id}&text=hacked"
    has_status_unauthorized
  end

  it "should not allow updating a comment " do
    patch "/api/v1/comments/#{@c.id}?text=hacked2"
    has_status_unauthorized
  end

  it "should not allow deleting a comment " do
    delete "/api/v1/comments/#{@c.id}"
    has_status_unauthorized
  end
end

describe "With valid token, API" do
	before(:all) do
		get "/api/login?username=p1@p1.com&password=p1"
	  	has_status_200	
	  	@token = JSON.parse(last_response.body)["token"]
		header "AUTHORIZATION", "bearer #{@token}"
		@u = User.first(email: "p1@p1.com")
    end
    
    it "should allow commenting on a post" do
        @p = Post.last
        post "/api/v1/posts/#{@p.id}/comments?post_id=#{@p.id}&text=woopwoop"
        @c2 = Comment.last
        has_status_200
        expect(@c2.user_id).to eq(@u.id)
        expect(@c2.post_id).to eq(@p.id)
        expect(@c2.text).to eq("woopwoop")
    end
  
    it "should allow updating a comment" do
        @c = Comment.first(user_id: @u.id)
        patch "/api/v1/comments/#{@c.id}?text=dope"
        has_status_200
        expect(@c.text).to eq("dope")
    end

    it "should allow deleting a comment" do
        @c = Comment.first(user_id: @u.id)
        delete "/api/v1/comments/#{@c.id}"
        @c2 = Comment.get(@c.id)
        expect(@c2).to be_nil
    end

    it "should not allow updating a comment belonging to another user" do
        @other_c = Comment.first
        patch "/api/v1/comments/#{@other_c.id}?text=hack"
        has_status_unauthorized
    end

    it "should not allow deleting a comment belonging to another user" do
        @other_c = Comment.first
        delete "/api/v1/comments/#{@other_c.id}"
        has_status_unauthorized
    end
end