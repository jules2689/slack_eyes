require 'bundler/setup'

require 'logger'
require 'json'

require 'slack_eyes/application'

module SlackEyes
  def self.app_root
    File.expand_path('../../', __FILE__)
  end

  def self.env
    ENV['RACK_ENV'] || 'development'
  end

  def self.load_secrets
    @secrets ||= begin
      SlackEyes.load_secrets_json
      secrets_json = File.join(app_root, 'config', 'secrets.json')
      return {} unless File.exists?(secrets_json)
      JSON.parse(File.read(secrets_json)).each_with_object({}) do |(key, value), secrets|
        secrets[key] = value
      end
    end
  end

  def self.load_secrets_json
    secrets_ejson_path = File.join(app_root, 'config', "secrets.#{env}.ejson")
    encrypted_json = JSON.parse(File.read(secrets_ejson_path))
    public_key = encrypted_json['_public_key']
    private_key_path = Pathname.new("/opt/ejson/keys/#{public_key}")
    if private_key_path.exist?
      Tempfile.open('secrets') do |io|
        success = system("ejson", "decrypt", secrets_ejson_path.to_s, out: io)
        io.rewind
        output = io.read
        raise "ejson: #{output}" unless success
        File.write(File.join(app_root, 'config', 'secrets.json'), output)
      end
    else
      warn <<~WARN
        #{'=' * 80}
        Private key is not listed in
        #{private_key_path}
        You won't be able to import services without setting up some keys.
        If you can, get the private key from 1Password and put it in that file.
        #{'=' * 80}
      WARN
    end
  end
end
