$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
ENV['RACK_ENV'] = 'test'

require 'slack_eyes'

require 'rack/test'
require 'minitest/pride'
require 'minitest/autorun'

class SlackEyesTest < Minitest::Test
  include Rack::Test::Methods
end
