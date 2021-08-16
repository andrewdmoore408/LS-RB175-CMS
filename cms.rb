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
  file = File.read(file_path(filename))

  case file_type(filename)
  when :markdown
    erb render_markdown(file)
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

# Return true if a filename is valid, else false
def valid_filename?(name)
  name.length.positive?
end

# Return true if username/password combo is valid, else false
def valid_signin?(credentials)
  valid_username = "admin"
  valid_password = "secret"

  credentials[:username] == valid_username && credentials[:password] == valid_password
end

# Home page
get "/" do
  if session[:user]
    pattern = File.join(data_path, "*")

    @files = Dir.glob(pattern).map do |path|
      File.basename(path)
    end

    erb :index
  else
    erb :not_logged_in
  end
end

# Show form to add a new file
get "/new" do
  erb :new_document
end

# Add a new file
post "/new" do
  new_filename = params[:new_filename]

  if valid_filename?(new_filename)
    file = File.open(file_path(new_filename), "w+")
    session[:success] = "#{new_filename} has been created."
    redirect "/"
  else
    session[:error] = "A name is required."
    status 422
    erb :new_document
  end
end

# Load a file and display it
get "/:filename" do
  filename = params[:filename]

  validate_file(filename)

  load_file_content(filename)
end

# Load a textarea to edit a file
get "/:filename/edit" do
  validate_file(params[:filename])

  @filepath = file_path(params[:filename])
  erb :edit_file
end

# Submit edits to file
post "/:filename" do
  params[:file_content]

  File.write(file_path(params[:filename]), params[:file_content])

  session[:success] = "#{params[:filename]} has been updated."
  redirect "/"
end

# Delete a file
post "/:filename/delete" do
  File.delete(file_path(params[:filename]))
  session[:success] = "#{params[:filename]} was deleted."

  redirect "/"
end

# Show form to sign in
get "/users/signin" do
  erb :signin
end

# Validate sign-in attempt: log in if valid, else reload login form
post "/users/signin" do
  credentials = {
    username: params[:username],
    password: params[:password]
  }

  if valid_signin?(credentials)
    session[:user] = params[:username]
    session[:success] = "Welcome!"

    redirect "/"
  else
    @entered_username = params[:username]
    session[:error] = "Invalid credentials"
    status 422
    erb :signin
  end
end

# Sign user out
post "/users/signout" do
  session[:user] = nil
  session[:success] = "You have been signed out."

  redirect "/"
end