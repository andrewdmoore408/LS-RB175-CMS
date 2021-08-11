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
      get "/view/#{filename}"

      included = filename.gsub(".txt", "")

      assert_equal 200, last_response.status
      assert_equal "text/plain", last_response["Content-Type"]
      assert last_response.body.include?(included)
    end
  end
end