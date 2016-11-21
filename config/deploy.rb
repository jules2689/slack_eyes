# config valid only for current version of Capistrano
lock '3.6.1'

server '159.203.13.16', user: 'root', port: 22, roles: [:web, :app, :db], primary: true

set :application,     'slack-eyes'
set :repo_url,        'git@github.com:jules2689/slack_eyes.git'
set :user,            'root'
set :chruby_ruby,     'ruby-2.3.1'
set :linked_dirs,     %w(log)
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
          latest_release = capture("ls #{fetch(:deploy_to)}/releases | sort").split("\n").last
          puts "Latest Release was #{latest_release}"
          execute :bundle, :exec, '/opt/rubies/ruby-2.3.1/bin/ruby', "#{fetch(:deploy_to)}/releases/#{latest_release}/slack_eyes_daemon.rb", 'start'
        end
      end
    end
  end

  desc "Kill the old Job"
  task :kill_old_app do
    on roles(:app) do
      within current_path do
        with RACK_ENV: fetch(:environment) do
          latest_release = capture("ls #{fetch(:deploy_to)}/releases | sort").split("\n").last
          puts "Latest Release was #{latest_release}"
          execute "kill -9 $(cat #{fetch(:deploy_to)}/releases/#{latest_release}/config.ru.pid) || true"
        end
      end
    end
  end

  desc "Check that the job is running"
  task :kill_old_app do
    on roles(:app) do
      within current_path do
        with RACK_ENV: fetch(:environment) do
          latest_release = capture("ls #{fetch(:deploy_to)}/releases | sort").split("\n").last
          puts "Latest Release was #{latest_release}"
          execute :bundle, :exec, '/opt/rubies/ruby-2.3.1/bin/ruby', "#{fetch(:deploy_to)}/releases/#{latest_release}/slack_eyes_daemon.rb", 'status'
        end
      end
    end
  end

  before :starting,  :check_revision
  before :starting,  :kill_old_app
  before :finishing, :start
  after  :finishing, :check_running
end
