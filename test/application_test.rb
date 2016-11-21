require_relative 'test_helper'

class ApplicationTest < SlackEyesTest
  def setup
  end

  def app
    SlackEyes::Application.new
  end
end
