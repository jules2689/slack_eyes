require 'slack_eyes/bluemix'
require 'slack_eyes/message_analyzer'
require 'slack_eyes/multi_io'
require 'slack'
require 'remote_syslog_logger'

module SlackEyes
  class Application
    def initialize
      @secrets = SlackEyes.load_secrets
      @channels_cache = {}
      @logger = Logger.new MultiIO.new(
        STDOUT,
        File.open("#{SlackEyes.app_root}/log/output.log", "a"),
        RemoteSyslogLogger::UdpSender.new(@secrets['papertrail_url'], @secrets['papertrail_port'], {})
      )
      @logger.info "Starting application in #{SlackEyes.env} mode"
      start
    end

    def start
      @logger.info 'Enabling slack message parsing'
      realtime_slack_client.on :message do |data|
        if data.user == @secrets['slack_user_id'] && data.type == 'message'
          # Receive Message, Cache Channel name
          @logger.info "Received message"
          analyzer = MessageAnalyzer.new(data, @logger, @channels_cache[data.channel])
          @channels_cache[data.channel] = analyzer.channel_name

          # Analyze Message, send if needed
          @logger.info "Analyzing data from a message in the channel `#{analyzer.channel_name}`"
          analyzer.analyze
          if analyzer.message
            @logger.info "Detected issues with message"
            analyzer.send_message
          else
            @logger.info "Did not detect issues with message"
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
