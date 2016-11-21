require 'httparty'
require 'json'

module SlackEyes
  class Bluemix
    include HTTParty
    base_uri 'https://gateway.watsonplatform.net/'

    def initialize(user, pass)
      @auth = { username: user, password: pass }
    end

    def check_tone(msg)
      self.class.post(
        '/tone-analyzer/api/v3/tone?version=2016-05-19',
        headers: { 'Content-Type' => 'application/json' },
        body: { text: msg }.to_json,
        basic_auth: @auth
      )
    end
  end
end
