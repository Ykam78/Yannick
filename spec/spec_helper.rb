# spec/spec_helper.rb
require 'rack/test'
require 'rspec'
require 'dm-rspec'

ENV['RACK_ENV'] = 'test'

require File.expand_path '../../app.rb', __FILE__

module RSpecMixin
  include Rack::Test::Methods

  def app() Sinatra::Application end
end



# For RSpec 2.x and 3.x
RSpec.configure do |c|
  c.include RSpecMixin 
  c.include(DataMapper::Matchers)
  DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/app_test.db")
  DataMapper.finalize
  User.auto_migrate!
  Post.auto_migrate!
  Like.auto_migrate!
  Comment.auto_migrate!
end