require 'json'
require 'slack_eyes/airtable_message'

module SlackEyes
  class MessageAnalyzer
    # rubocop:disable Metrics/LineLength
    GLOSSARY = {
      'Anger' => 'Likelihood of writer being perceived as angry. Low value indicates unlikely to be perceived as angry. High value indicates very likely to be perceived as angry.',
      'Disgust' => 'Likelihood of writer being perceived as disgusted. Low value, unlikely to be perceived as disgusted. High value, very likely to be perceived as disgusted.',
      'Fear' => 'Likelihood of writer being perceived as scared. Low value indicates unlikely to be perceived as fearful. High value, very likely to be perceived as scared.',
      'Sadness' => 'Likelihood of writer being perceived as sad. Low value, unlikely to be perceived as sad. High value very likely to be perceived as sad.',
      'Agreeableness' => 'Higher value, writer more likely to be perceived as, compassionate and cooperative towards others.'
    }
    # rubocop:enable Metrics/LineLength

    HIGH_TONE_THRESHOLD = 0.5
    LOW_TONE_THRESHOLD = 0.35

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

      current_records = AirtableMessage.records(fields: %w(channel message))
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
      airtable_message = AirtableMessage.new(
        message: data.text,
        channel: channel_name,
        results: msg,
        raw_results: @resp.to_json,
        created_at: Time.now.utc
      )
      airtable_message.create
    end

    def analyze_response(resp)
      high_tones = {}
      low_tones = {}

      resp.parsed_response['document_tone']['tone_categories'].each do |category|
        category['tones'].each do |tone|
          high_tones[tone['tone_name']] = tone['score'] if tone['score'] >= HIGH_TONE_THRESHOLD
          low_tones[tone['tone_name']] = tone['score'] if tone['score'] < LOW_TONE_THRESHOLD
        end
      end

      high_tones_intersection = high_tones.keys & %w(Anger Sadness Disgust Fear Tentative)
      low_tones_intersection = low_tones.keys & %w(Agreeableness)

      return nil if high_tones_intersection.empty? && low_tones_intersection.empty?

      message = ["This message exhibited:"]

      message << "\n*High Tones*" unless high_tones_intersection.empty?
      high_tones_intersection.each do |high_tone|
        message << "*#{high_tone}* (#{high_tones[high_tone]}): #{GLOSSARY[high_tone]}"
      end

      message << "\n*Low Tones*" unless low_tones_intersection.empty?
      low_tones_intersection.each do |low_tone|
        message << "*#{low_tone}* (#{low_tones[low_tone]}): #{GLOSSARY[low_tone]}"
      end

      message.join("\n")
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
