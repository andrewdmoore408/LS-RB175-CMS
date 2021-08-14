require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'
require 'redcarpet'

ROOT = File.expand_path("..", __FILE__)
DATA_DIR = "/public/data"

configure do
  enable :sessions
  set :session_secret, 'secret'
end

helpers do
  def only_filename(file)
    File.basename(file)
  end

  def load_file(filepath)
    File.read(filepath)
  end
end

def data_path
  if ENV["RACK_ENV"] == "test"
    ROOT + File.expand_path("/test/data", __FILE__)
  else
    ROOT + File.expand_path("/public/data", __FILE__)
  end
end

def file_path(filename)
  File.join(data_path(), filename)
end

def file_type(filename)
  extension = filename.split(".").last

  case extension
  when "md"
    :markdown
  when "txt"
    :plaintext
  end
end

def load_file_content(filename)
  file = nil

  # begin
    file = File.read(file_path(filename))
  # rescue => e
  #    "#{e.message}"
  # end

  case file_type(filename)
  when :markdown
    body render_markdown(file)
  when :plaintext
    status 200
    headers "Content-Type" => "text/plain"
    body file
  else
    body file
  end
end

def render_markdown(file)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render(file)
end

# Ensure that a file exists; if not, set a flash error message and redirect back to index
def validate_file(filename)
  unless File.file?(file_path(filename))
    session[:error] = "#{filename.split("/").last} does not exist."
    redirect "/"
  end
end

get "/" do
  pattern = File.join(data_path, "*")

  @files = Dir.glob(pattern).map do |path|
    File.basename(path)
  end

  erb :files
end

get "/:filename" do
  filename = params[:filename]

  validate_file(filename)

  load_file_content(filename)
end

get "/:filename/edit" do
  validate_file(params[:filename])

  @filepath = file_path(params[:filename])
  puts "/:filename/edit FILEPATH IS #{@filepath}"
  erb :edit_file
end

post "/:filename" do
  params[:file_content]

  File.write(file_path(params[:filename]), params[:file_content])

  session[:success] = "#{params[:filename]} has been updated."
  redirect "/"
end