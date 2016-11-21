# rubocop:disable Metrics/LineLength
require_relative 'test_helper'

class MessageAnalyzerTest < SlackEyesTest
  def setup
    @logger = Logger.new('/dev/null')
    @app = SlackEyes::MessageAnalyzer.new(
      OpenStruct.new(
        text: 'text',
        user: '12345',
        channel: 'channel'
      ),
      @logger
    )
  end

  def test_analyze_with_no_triggers
    mock_bluemix('no_trigger_tones')
    @app.analyze
    assert_nil @app.message
  end

  def test_analyze_with_high_tone_triggers
    mock_bluemix('high_tones')
    @app.analyze
    assert_match 'Anger* (0.55482): Likelihood of writer being perceived as angry.', @app.message
  end

  def test_channel_name_with_slack_channel
    Slack::Web::Client.any_instance
      .expects(:channels_info)
      .with(channel: 'channel')
      .returns(OpenStruct.new(channel: OpenStruct.new(name: 'channel name')))
    assert_equal 'channel name', @app.channel_name
  end

  def test_channel_name_with_private_channel
    Slack::Web::Client.any_instance.expects(:channels_info).raises(Slack::Web::Api::Error.new('error'))
    Slack::Web::Client.any_instance
      .expects(:groups_info)
      .with(channel: 'channel')
      .returns(OpenStruct.new(group: OpenStruct.new(name: 'group name')))
    assert_equal 'group name', @app.channel_name
  end

  def test_channel_name_with_direct_message
    Slack::Web::Client.any_instance.expects(:channels_info).raises(Slack::Web::Api::Error.new('error'))
    Slack::Web::Client.any_instance.expects(:groups_info).raises(Slack::Web::Api::Error.new('error'))
    assert_equal 'direct message', @app.channel_name
  end

  def test_send_message_with_invalid_user
    @logger = Logger.new('/dev/null')
    @app = SlackEyes::MessageAnalyzer.new(
      OpenStruct.new(
        text: 'text',
        user: 'invalid user',
        channel: 'channel'
      ),
      @logger
    )
    assert_nil @app.send_message
  end

  def test_send_message_with_valid_user_but_already_submitted_to_airtable
    @app.stubs(:channel_name).returns('channel')
    AirtableModels::Message.expects(:records).returns(
      [
        OpenStruct.new(
          fields: {
            'channel' => 'channel',
            'message' => 'text'
          }
        )
      ]
    )
    assert_nil @app.send_message
  end

  def test_valid_message_is_sent_to_slack_and_airtable
    mock_bluemix('high_tones')
    @app.stubs(:channel_name).returns('channel')
    AirtableModels::Message.expects(:records).returns([])

    # Slack
    Slack::Web::Client.any_instance.expects(:chat_postMessage).with(
      channel: '12345',
      text: "The message you posted in the channel *channel* may not have been the best words to use\n> text\n\nThis message exhibited:\n\n*High Tones*\n*Anger* (0.55482): Likelihood of writer being perceived as angry. Low value indicates unlikely to be perceived as angry. High value indicates very likely to be perceived as angry.",
      username: 'Tone Analyzer',
      as_user: false
    )

    # Airtable
    msg_mock = mock
    AirtableModels::Message.expects(:new).returns(msg_mock)
    AirtableModels::AngerMessage.expects(:new).with(score: 0.55482).returns(msg_mock)
    msg_mock.expects(:fields).returns({})
    msg_mock.expects(:create).twice.returns(true)

    @app.analyze
    @app.send_message
  end

  def mock_bluemix(file)
    file_path = File.join(SlackEyes.app_root, 'test', 'data', "#{file}.json")
    SlackEyes::Bluemix.any_instance.expects(:check_tone).with('text').returns(
      OpenStruct.new(parsed_response: JSON.parse(File.read(file_path)))
    )
  end
end
