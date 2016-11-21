require 'airrecord'

module AirtableModels
  class Message < Airrecord::Table
    def self.api_key
      SlackEyes.load_secrets['airtable_api_key']
    end

    def self.base_key
      SlackEyes.load_secrets['airtable_base_key']
    end

    def self.table_name
      SlackEyes.env == 'production' ? 'messages' : 'messages_dev'
    end

    def self.from_message(msg, score: nil)
      fields = msg.fields.merge(score: score)
      fields.delete('id')
      new(fields)
    end
  end
end
