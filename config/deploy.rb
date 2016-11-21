# config valid only for current version of Capistrano
lock '3.6.1'

server '159.203.13.16', user: 'root', port: 22, roles: [:web, :app, :db], primary: true

set :application,     'slack-eyes'
set :repo_url,        'git@github.com:jules2689/slack_eyes.git'
set :user,            'root'
set :chruby_ruby,     'ruby-2.3.1'
set :linked_dirs,     %w(log)
set :linked_files,    %w(config.ru.pid)
set :environment,     'production'

namespace :deploy do
  desc "Make sure local git is in sync with remote."
  task :check_revision do
    on roles(:app) do
      unless `git rev-parse HEAD` == `git rev-parse origin/master`
        puts "WARNING: HEAD is not the same as origin/master"
        puts "Run `git push` to sync changes."
        exit
      end
    end
  end

  desc "Start Job"
  task :start do
    on roles(:app) do
      within current_path do
        with RACK_ENV: fetch(:environment) do
          execute :bundle, :exec, '/opt/rubies/ruby-2.3.1/bin/ruby', "#{current_path}/slack_eyes_daemon.rb", 'restart'
        end
      end
    end
  end

  before :starting, :check_revision
  before :finishing, :start
end
