require 'slack_eyes/airtable_models/message'

module AirtableModels
  class AngerMessage < Message
    def self.table_name
      SlackEyes.env == 'production' ? 'anger messages' : 'anger messages dev'
    end
  end
end
