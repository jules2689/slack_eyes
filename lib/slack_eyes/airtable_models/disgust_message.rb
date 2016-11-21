require 'slack_eyes/airtable_models/message'

module AirtableModels
  class DisgustMessage < Message
    def self.table_name
      'disgust messages'
    end
  end
end
