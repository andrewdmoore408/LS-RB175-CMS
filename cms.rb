require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'
require 'redcarpet'

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

def file_type(filename)
  extension = filename.split(".").last

  case extension
  when "md"
    :markdown
  when "txt"
    :plaintext
  end
end

def render_markdown(file)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render(file)
end

get "/" do
  @files = Dir.glob(root + data_dir + "/*")

  erb :files
end

get "/:filename" do
  filename = params[:filename]
  filepath = root + data_dir + "/" + filename

  unless File.file?(filepath)
    session[:error] = "#{filename} does not exist."
    redirect "/"
  end

  file = File.read(root + data_dir + "/" + filename)

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