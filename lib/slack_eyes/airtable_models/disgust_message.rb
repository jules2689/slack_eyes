require 'slack_eyes/airtable_models/message'

module AirtableModels
  class DisgustMessage < Message
    def self.table_name
      SlackEyes.env == 'production' ? 'disgust messages' : 'disgust messages dev'
    end
  end
end
