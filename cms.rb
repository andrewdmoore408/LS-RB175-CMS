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

def file_path(filename)
  ROOT + DATA_DIR + "/" + filename
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

def load_file_content(filepath)

  file = File.read(filepath)

  case file_type(filepath)
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

def validate_file(filepath)
  unless File.file?(filepath)
    session[:error] = "#{filepath.split("/").last} does not exist."
    redirect "/"
  end
end

get "/" do
  @files = Dir.glob(ROOT + DATA_DIR + "/*")

  erb :files
end

get "/:filename" do
  filename = params[:filename]
  filepath = ROOT + DATA_DIR + "/" + filename

  validate_file(filepath)

  load_file_content(filepath)
end

get "/:filename/edit" do
  @filepath = ROOT + DATA_DIR + "/" + params[:filename]

  validate_file(@filepath)

  erb :edit_file
end

post "/:filename" do
  params[:file_content]

  File.write(file_path(params[:filename]), params[:file_content])

  session[:success] = "#{params[:filename]} has been updated."
  redirect "/"
end