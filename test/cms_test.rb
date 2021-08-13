ENV["RACK_ENV"] = "test"

require 'minitest/autorun'
require 'minitest/reporters'
require 'rack/test'

require_relative "../cms"

Minitest::Reporters.use!

class CMSTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def setup
    @filenames = ["changes.txt", "about.txt", "history.txt"]
  end

  def test_index
    get "/"

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    @filenames.each do |filename|
      assert_includes last_response.body, filename
    end
  end

  def test_view_filename
    @filenames.each do |filename|
      get "/#{filename}"

      assert_equal 200, last_response.status
      assert_equal "text/plain", last_response["Content-Type"]
    end
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

    get "/marky_markdown.md"

    assert_equal 200, last_response.status
    assert_includes last_response.body, "<em>"
    assert_includes last_response.body, "<li>"
    refute_includes last_response.body, "_"
  end

# test/cms_test.rb
  def test_editing_document
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
end