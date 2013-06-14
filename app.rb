require 'rubygems'
require 'sinatra'
require 'sinatra/json'
require 'json'
require 'data_mapper'
require 'thin'
require 'twilio-ruby'
require 'bcrypt'

enable :sessions

DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/development.db")

class Item
  include DataMapper::Resource
  property :id, Serial, :key => true
  property :name, String
  property :text, String
  property :reminder, Boolean, :default  => false
  property :reminded, Boolean, :default  => false
  property :number, String
  property :done, Boolean, :default  => false

  property :priority, Integer
  property :created_at, DateTime
  property :updated_at, DateTime
  property :reminded_at, DateTime
end

class User
  include DataMapper::Resource
  property :id, Serial, :key => true
  property :username, String
  property :salt, String
  property :passwordhash, String
  property :created_at, DateTime
  property :updated_at, DateTime
end

class Admin
  include DataMapper::Resource
  property :id, Serial
  property :username, String
  property :password, String
  property :created_at, DateTime
  property :updated_at, DateTime
end

DataMapper.finalize.auto_upgrade!

use Rack::Session::Cookie, :key => 'rack.session',
                           :secret => 'adminha!@#$00555ascacascasc34234(**&*&$%$$#####222'

@log = Array.new

helpers do
  
  def login?
    if session[:username].nil?
      return false
    else
      return true
    end
  end
  
  def login_forward
    if session[:username].nil?
      redirect "/login"
    end
  end

  def username
    return session[:username]
  end
  
end


after '/item/:id/done' do
  item = Item.all(:done => false, :order => :priority)
  #if item[2].reminder
  if item[2]
    
    #@account_sid = 'AC7914eff096444c577915cbff191a094d'
    #@auth_token = 'e746e8040fa3bee45c936a341bca7c7e'
    #send SMS!!!
    #@client = Twilio::REST::Client.new(@account_sid, @auth_token)

    #@account = @client.account
    #@message = @account.sms.messages.create({:from => '+15122702451', :to => '+60164408334', :body => item[2].text.to_s})
    item[2].reminded_at = Time.now
    item[2].reminded = true
    item[2].save
  end
  #end
end

get '/' do
    login_forward
    @items = Item.all(:done => false, :order => :priority )
    erb :index
  
end

post '/item' do
  login_forward
  i = Item.new
  i.priority = Item.count
  i.text = params[:text]
  i.name = params[:name]
  i.number = params[:number]
  i.created_at = Time.now
  i.save
  redirect '/'
end

get '/item/:id/show' do
  @item = Item.get(params[:id].to_i)
  erb :showitem
end

get '/item/:id' do
  login_forward
  @item = Item.get(params[:id].to_i)
  erb :edititem
end

put '/item/:id' do
  login_forward
  i = Item.get(params[:id].to_i)
  i.text = params[:text]
  i.name = params[:name]
  i.updated_at = Time.now
  i.save
  redirect '/'
end

get '/item/:id/done' do
  login_forward
  i = Item.get(params[:id].to_i)
  i.done = true
  i.save
  redirect '/'
end

get '/item/:id/up' do
  login_forward
  i = Item.get(params[:id].to_i)
  
  i.priority = i.priority-1
  i.save

  redirect '/'
end

get '/item/:id/down' do
  login_forward
  i = Item.get(params[:id].to_i)

  i.priority = i.priority+1
  i.save

  redirect '/'
end


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