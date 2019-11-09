require 'data_mapper' # metagem, requires common plugins too.
require "active_support/core_ext/hash/except"

# need install dm-sqlite-adapter
# if on heroku, use Postgres database
# if not use sqlite3 database I gave you
if ENV['DATABASE_URL']
  DataMapper::setup(:default, ENV['DATABASE_URL'] || 'postgres://localhost/mydb')
else
  DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/app.db")
end

class User
    include DataMapper::Resource
    property :id, Serial
    property :email, Text
    property :bio, Text
    property :profile_image_url, Text
    property :password, Text
    property :created_at, DateTime
    property :role_id, Integer, default: 1

    def administrator?
        return role_id == 0
    end 

    def user?
        return role_id != 0
    end
    
    def login(password)
    	return self.password == password
    end
end

class Post
    include DataMapper::Resource
    property :id, Serial
    property :caption, Text
    property :image_url, Text
    property :created_at, DateTime
    property :user_id, Integer
    #fill in the rest
end

class Comment
    include DataMapper::Resource
    property :id, Serial
    property :user_id, Integer
    property :post_id, Integer
    property :text, Text
    property :created_at, DateTime
    #fill in the rest
end
class Like
    include DataMapper::Resource
    property :id, Serial
    property :user_id, Integer
    property :post_id, Integer
    property :created_at, DateTime
    #fill in the rest
end

# Perform basic sanity checks and initialize all relationships
# Call this when you've defined all your models
DataMapper.finalize

# automatically create the post table
User.auto_upgrade!
Post.auto_upgrade!
Like.auto_upgrade!
Comment.auto_upgrade!

DataMapper::Model.raise_on_save_failure = true  # globally across all model