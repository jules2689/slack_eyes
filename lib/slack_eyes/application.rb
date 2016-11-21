require 'slack_eyes/bluemix'
require 'slack_eyes/message_analyzer'
require 'slack'

module SlackEyes
  class Application
    def initialize
      @secrets = SlackEyes.load_secrets
      @logger = Logger.new(STDOUT)
      start
    end

    def start
      @logger.info 'Enabling slack message parsing'
      realtime_slack_client.on :message do |data|
        if data.user == @secrets['slack_user_id'] && data.type == 'message'
          analyzer = MessageAnalyzer.new(data)
          if analyzer.message
            @logger.info "Detected issues with #{data.inspect}"
            analyzer.send_message
          end
        end
      end
      realtime_slack_client.start!
    end

    private

    def realtime_slack_client
      @realtime_slack_client ||= begin
        Slack.configure do |config|
          config.token = @secrets['slack_token']
        end
        Slack::RealTime::Client.new
      end
    end
  end
end
