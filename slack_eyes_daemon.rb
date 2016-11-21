require 'daemons'

ENV['RACK_ENV'] = 'production'
Daemons.run('config.ru')
