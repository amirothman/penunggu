require 'rubygems'
require 'bcrypt'
require 'sinatra'
require 'data_mapper'

enable :sessions
use Rack::Session::Cookie, :key => 'rack.session',
                           :secret => 'adminha!@#$00555ascacascasc34234(**&*&$%$$#####222'

#userTable = {}

DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/development.db")

class User
  include DataMapper::Resource
  property :id, Serial, :key => true
  property :username, String
  property :salt, String
  property :passwordhash, String
  property :created_at, DateTime
  property :updated_at, DateTime
end

DataMapper.finalize.auto_upgrade!

helpers do
  
  def login?
    if session[:username].nil?
      return false
    else
      return true
    end
  end
  
  def username
    return session[:username]
  end
  
end

get "/" do
  if login?
    erb :index
  else
    redirect "/login"
  end
end

######################
######################

get "/signup" do
  erb :signup
end

post "/signup" do
  
  if params[:password] == params[:checkpassword] && User.first(:username => params[:username])==nil
    
    password_salt = BCrypt::Engine.generate_salt
    password_hash = BCrypt::Engine.hash_secret(params[:password], password_salt)
    
    user = User.new
    user.username = params[:username]
    user.salt = password_salt
    user.passwordhash = password_hash
    user.created_at = Time.now
    user.save!
    session[:username] = params[:username]
    redirect "/"
  else
    redirect "/signup"
  end
end

get "/login" do
  erb :login
end

post "/login" do
  if User.first(:username => params[:username])
    user = User.first(:username => params[:username])
    if user.passwordhash == BCrypt::Engine.hash_secret(params[:password], user.salt)
      session[:username] = params[:username]
      redirect "/"
    end
  end
  erb :error
end

get "/logout" do
  session.clear
  redirect "/"
end