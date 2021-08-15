ENV["RACK_ENV"] = "test"

require 'minitest/autorun'
require 'minitest/reporters'
require 'rack/test'
require 'fileutils'

require_relative "../cms"

Minitest::Reporters.use!

class CMSTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def setup
    FileUtils.mkdir_p(data_path)
  end

  def teardown
    FileUtils.rm_rf(data_path)
  end

  def create_document(name, content = "")
    File.open(File.join(data_path, name), "w") do |file|
      file.write(content)
    end
  end

  def session
    last_request.env["rack.session"]
  end

  def test_index_signed_in
    create_document "about.md"
    create_document "changes.txt"

    get "/", {}, { "rack.session" => { user: "admin" } }

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body, "about.md"
    assert_includes last_response.body, "changes.txt"

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
  end

  def test_view_filename
    filename = "A_test.txt"
    create_document filename

    get "/#{filename}"

    assert_equal 200, last_response.status
    assert_equal "text/plain", last_response["Content-Type"]
  end

  def test_invalid_file_access
    nonexistent = "notreal.txt"

    get "/#{nonexistent}"
    assert_equal 302, last_response.status

    get last_response["location"]
    assert_equal 200, last_response.status
    assert_includes last_response.body, "#{nonexistent} does not exist."

    get "/"
    refute_includes last_response.body, "#{nonexistent} does not exist."
  end

  def test_markdown_to_html
    create_document "marky_markdown.md", "<em><li></li></em>"
    get "/marky_markdown.md"

    assert_equal 200, last_response.status
    assert_includes last_response.body, "<em>"
    assert_includes last_response.body, "<li>"
  end

  def test_editing_document
    create_document "changes.txt"
    get "/changes.txt/edit"

    assert_equal 200, last_response.status
    assert_includes last_response.body, "<textarea"
    assert_includes last_response.body, %q(<input type="submit")
  end

  def test_updating_document
    post "/changes.txt", file_content: "new content"

    assert_equal 302, last_response.status

    get last_response["Location"]

    assert_includes last_response.body, "changes.txt has been updated"

    get "/changes.txt"
    assert_equal 200, last_response.status
    assert_includes last_response.body, "new content"
  end

  def test_view_new_document_form
    get "/new"

    assert_equal 200, last_response.status
    assert_includes last_response.body, "<input"
    assert_includes last_response.body, %q(<button type="submit")
  end

  def test_create_new_document
    post "/new", {new_filename: "test.txt"}, { "rack.session" => { user: "admin"} }
    assert_equal 302, last_response.status

    get last_response["Location"]
    assert_includes last_response.body, "test.txt has been created"

    get "/"
    assert_includes last_response.body, "test.txt"
  end

  def test_create_new_document_without_filename
    post "/new", new_filename: ""
    assert_equal 422, last_response.status
    assert_includes last_response.body, "A name is required"
  end

  def test_delete_document
    create_document "toDelete.txt"

    post "/toDelete.txt/delete", filename: "toDelete.txt"

    assert_equal 302, last_response.status

    get last_response["Location"]
    assert_includes last_response.body, "toDelete.txt was deleted."

    get "/"
    refute_includes last_response.body, "toDelete.txt"
  end

  def test_signed_out_index
    get "/"

    assert_includes last_response.body, "You must sign in to use this site"
  end

  def test_signing_in
    create_document "testing.txt"

    get "/users/signin"

    assert_includes last_response.body, "Username:"
    assert_includes last_response.body, "Password:"

    post "/users/signin", { username: "admin", password: "secret" }

    assert_equal 302, last_response.status

    get last_response["Location"]
    assert last_response.ok?
    assert_includes last_response.body, "testing.txt"
    assert_includes last_response.body, "Signed in"
  end
end