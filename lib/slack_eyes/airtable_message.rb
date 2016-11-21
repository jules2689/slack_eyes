require 'airrecord'

class AirtableMessage < Airrecord::Table
  def self.api_key
    SlackEyes.load_secrets['airtable_api_key']
  end

  def self.base_key
    SlackEyes.load_secrets['airtable_base_key']
  end

  def self.table_name
    SlackEyes.load_secrets['airtable_table']
  end
end
