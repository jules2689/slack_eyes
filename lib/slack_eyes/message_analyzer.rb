require 'json'
require 'slack_eyes/airtable_models/message'
require 'slack_eyes/airtable_models/anger_message'
require 'slack_eyes/airtable_models/disgust_message'

module SlackEyes
  class MessageAnalyzer
    # rubocop:disable Metrics/LineLength
    GLOSSARY = {
      'Anger' => 'Likelihood of writer being perceived as angry. Low value indicates unlikely to be perceived as angry. High value indicates very likely to be perceived as angry.',
      'Disgust' => 'Likelihood of writer being perceived as disgusted. Low value, unlikely to be perceived as disgusted. High value, very likely to be perceived as disgusted.',
    }
    # rubocop:enable Metrics/LineLength
    HIGH_TONES = %w(Anger Disgust).freeze

    THRESHOLDS = {
      'Anger' => 0.5,
      'Disgust' => 0.5
    }

    attr_accessor :message, :data

    def initialize(data, logger, channel = nil)
      @logger = logger
      @secrets = SlackEyes.load_secrets
      @channel_name = channel
      self.data = data
    end

    def analyze
      @resp = bluemix_client.check_tone(data.text)
      self.message = analyze_response(@resp)
    end

    def send_message
      unless data.user == @secrets['slack_user_id']
        @logger.info "Returning, not the right user"
        return
      end

      current_records = AirtableModels::Message.records(fields: %w(channel message))
      if current_records.any? { |r| r.fields['channel'] == channel_name && r.fields['message'] == data.text }
        @logger.info "Returning, already detected the message in airtable"
        return
      end

      formatted_original_message = data.text.split("\n").collect { |l| "> #{l}" }.join("\n")
      msg = [
        "The message you posted in the channel *#{channel_name}* may not have been the best words to use",
        formatted_original_message + "\n",
        message
      ].join("\n")

      post_to_slack(msg)
      post_to_airtable(msg)
    end

    def channel_name
      @channel_name ||= begin
        slack_client.channels_info(channel: data.channel).channel.name
      rescue Slack::Web::Api::Error
        slack_client.groups_info(channel: data.channel).group.name
      end
    end

    private

    def post_to_slack(msg)
      slack_client.chat_postMessage(
        channel: @secrets['slack_user_id'],
        text: msg,
        username: 'Tone Analyzer',
        as_user: false
      )
    end

    def post_to_airtable(msg)
      airtable_message = AirtableModels::Message.new(
        message: data.text,
        channel: channel_name,
        results: msg,
        raw_results: @resp.to_json,
        created_at: Time.now.utc
      )
      airtable_message.create

      high_tones(@resp).each do |high_tone, score|
        case high_tone
        when 'Anger'
          AirtableModels::AngerMessage.from_message(airtable_message, score: score).create
        when 'Disgust'
          AirtableModels::DisgustMessage.from_message(airtable_message, score: score).create
        end
      end
    end

    def analyze_response(resp)
      high_tones_intersection = high_tones(resp).keys & HIGH_TONES
      return nil if high_tones_intersection.empty?

      message = ["This message exhibited:"]
      message << "\n*High Tones*" unless high_tones_intersection.empty?
      high_tones_intersection.each do |high_tone|
        message << "*#{high_tone}* (#{high_tones(resp)[high_tone]}): #{GLOSSARY[high_tone]}"
      end
      message.join("\n")
    end

    def high_tones(resp)
      @high_tones ||= resp.parsed_response['document_tone']['tone_categories'].each_with_object({}) do |cat, h_tones|
        cat['tones'].each do |tone|
          threshold = THRESHOLDS[tone['tone_name']] || 0.5
          h_tones[tone['tone_name']] = tone['score'] if tone['score'] >= threshold
        end
      end
    end

    def bluemix_client
      SlackEyes::Bluemix.new(
        @secrets['bluemix_username'],
        @secrets['bluemix_password']
      )
    end

    def slack_client
      @slack_client ||= begin
        Slack.configure do |config|
          config.token = @secrets['slack_token']
        end
        Slack::Web::Client.new
      end
    end
  end
end
