require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'

root = File.expand_path("..", __FILE__)
data_dir = "/public/data"

helpers do
  def only_filename(file)
    File.basename(file)
  end
end

get "/" do
  @files = Dir.glob(root + data_dir + "/*")

  erb :files
end

get "/view/:filename" do
  file = File.read(root + data_dir + "/" + params[:filename])

  status 200
  headers "Content-Type" => "text/plain"
  body file
end