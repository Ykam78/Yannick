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
  	@p.user_id = @u2.id
  	@p.save

  	@p = Post.new
  	@p.caption = "Sample post"
  	@p.image_url = "https://via.placeholder.com/1080.jpg"
  	@p.user_id = @u.id
  	@p.save
  end

  it "should have two users in test database" do 
  	expect(User.all.count).to eq(2)
  end

  it "should not allow creating a post" do
  	post '/api/v1/posts?caption=sweet&content=https://via.placeholder.com/1080.jpg'
  	has_status_unauthorized
	end
	
	it "should not allow reading a single post" do
  	get "/api/v1/posts/#{@p.id}"
  	has_status_unauthorized
	end
	
	it "should not allow reading all posts" do
  	get "/api/v1/posts"
  	has_status_unauthorized
	end
	
	it "should not allow reading /api/v1/my_posts" do
  	get "/api/v1/my_posts"
  	has_status_unauthorized
  end

  it "should not allow deleting a post" do
  	p = Post.last
  	delete "/api/v1/posts/#{@p.id}"
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

	it "should allow accessing all posts" do
		get "/api/v1/posts"
		#puts last_response.status
		# Rspec 2.x
		has_status_200
	  end
	
	  it "should include all posts on /api/v1/posts" do
		get "/api/v1/posts"
		json_response = last_response.body
		posts = JSON.parse(json_response)
	
		post_ids = []
	
		posts.each do |p|
		  post_ids << p["id"]
		  post_obj = Post.get(p["id"])
		  contains_post_attributes(p)
		  json_hash_matches_object?(p, post_obj)
		end
	
		master_posts = Post.all
		master_post_ids = []
	
		master_posts.each do |p|
		  master_post_ids << p.id
		end
	
		expect((post_ids - master_post_ids).empty?).to eq(true)
	  end
	
	  it "should include data for post with id 1 on /api/v1/posts/1" do
		get "/api/v1/posts/1"
		post_json = last_response.body
		post_hash = JSON.parse(post_json)
		post = Post.get(1)
	
		has_status_200
		json_hash_matches_object?(post_hash, post)
	  end
	
	  it "should allow accessing a specific post" do
		  p = Post.last
		  get "/api/v1/posts/#{p.id}"
		  has_status_200
		  post_json = last_response.body
		  post_hash = JSON.parse(post_json)
		  json_hash_matches_object?(post_hash, p)
	  end
	
	  it "should 404 for non-existent post" do
		  p = Post.last
		  get "/api/v1/posts/#{p.id + 200}"
		  has_status_404
	  end
	
	  it "should display all of a users posts on /api/v1/my_posts" do
		get "/api/v1/my_posts"
		json_response = last_response.body
		posts = JSON.parse(json_response)
	
		post_ids = []
	
		posts.each do |p|
		  post_ids << p["id"]
		  post_obj = Post.get(p["id"])
		  contains_post_attributes(p)
		  json_hash_matches_object?(p, post_obj)
		end
	
		master_posts = Post.all(user_id: @u.id)
		master_post_ids = []
	
		master_posts.each do |p|
		  master_post_ids << p.id
		end
	
		expect((post_ids - master_post_ids).empty?).to eq(true)
	  end
	
		it "should allow creating a post" do
			post "/api/v1/posts", caption: "cool image", image: Rack::Test::UploadedFile.new("./misc/avatar.png", "text/png")
			has_status_200
			@p = Post.last
			expect(@p.image_url).to include("s3.amazonaws.com")
			expect(@p.caption).to eq("cool image")
		end
	
		it "should allow updating a post" do
			@p = Post.last
			patch "/api/v1/posts/#{@p.id}", caption: "sinatra4lyfe"
			has_status_200
			expect(@p.image_url).to include("s3.amazonaws.com")
			expect(@p.caption).to eq("sinatra4lyfe")
		end
	
		it "should allow deleting a post" do
			p = Post.last
			delete "/api/v1/posts/#{p.id}"
			expect(Post.get(p.id)).to be_nil
		end

		it "should not allow deleting another users post" do
			p = Post.first
			delete "/api/v1/posts/#{p.id}"
			has_status_unauthorized
		end
end