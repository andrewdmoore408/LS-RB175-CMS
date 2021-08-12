require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'
require "redcarpet"

root = File.expand_path("..", __FILE__)
data_dir = "/public/data"

configure do
  enable :sessions
  set :session_secret, 'secret'
end

helpers do
  def only_filename(file)
    File.basename(file)
  end
end

get "/" do
  @files = Dir.glob(root + data_dir + "/*")

  erb :files
end

get "/:filename" do
  filename = params[:filename]
  filepath = root + data_dir + "/" + filename
  file = nil

  if File.file?(filepath)
    file = File.read(root + data_dir + "/" + filename)
  else
    session[:error] = "#{filename} does not exist."
    redirect "/"
  end

  status 200
  headers "Content-Type" => "text/plain"
  body file
end