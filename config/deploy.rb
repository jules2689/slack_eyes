# config valid only for current version of Capistrano
lock '3.6.1'

server '159.203.23.61', user: 'root', port: 22, roles: [:web, :app, :db], primary: true

set :application,     'slack-eyes'
set :repo_url,        'git@github.com:jules2689/slack_eyes.git'
set :user,            'root'
set :chruby_ruby,     'ruby-2.3.1'
set :linked_dirs,     %w(log)

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
    sh "RACK_ENV=production ruby config.ru &"
  end

  before :starting, :check_revision
  before :finishing, :start
end
