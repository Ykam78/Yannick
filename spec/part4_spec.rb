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
  end

  it "should have two users in test database" do 
  	expect(User.all.count).to eq(2)
  end

  it "should not allow liking a post" do
  	p = Post.last
  	post "/api/v1/posts/#{@p.id}/likes"
  	has_status_unauthorized
  end

  it "should not allow unliking a post" do
    p = Post.last
    delete "/api/v1/posts/#{@p.id}/likes"
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
    
    it "should allow liking a post" do
        p = Post.last
        post "/api/v1/posts/#{p.id}/likes"
        like = Like.first(user_id: @u.id, post_id: p.id)
        expect(like).not_to be_nil
    end
  
    it "should allow unliking a post" do
      p = Post.last
      delete "/api/v1/posts/#{p.id}/likes"
      like = Like.first(user_id: @u.id, post_id: p.id)
      expect(like).to be_nil
  end

end