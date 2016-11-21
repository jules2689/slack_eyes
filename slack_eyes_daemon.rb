require 'daemons'

ENV['RACK_ENV'] = 'production'
Daemons.run(File.join(File.expand_path('../', __FILE__), 'config.ru'))
