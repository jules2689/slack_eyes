require 'airrecord'

class AirtableMessage < Airrecord::Table
  secrets = JSON.parse(File.read('config/secrets.json'))
  self.api_key = secrets['airtable_api_key']
  self.base_key = secrets['airtable_base_key']
  self.table_name = secrets['airtable_table']
end
