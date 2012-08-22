set :config_yaml, YAML.load_file(File.dirname(__FILE__) + '/deploy_config.yml')

set :stages, ['development']
set :default_stage, 'development'
require 'capistrano/ext/multistage'

set :application, "gitlab-dev"

set :scm, :git
set :use_sudo, false
set :scm_verbose, true
set :repository_cache, "remote_cache"

set :git_shallow_clone, 1
set :deploy_via, :remote_cache

set :deploy_via, :checkout
set :ssh_options, { :forward_agent => true }

def current_git_branch
  branch = `git symbolic-ref HEAD 2> /dev/null`.strip.gsub(/^refs\/heads\//, '')
  logger.info "Deploying branch #{branch}"
  branch
end

before 'deploy:update' do
  set :branch, current_git_branch
end

namespace :deploy do
  desc "Restart of Unicorn"
  task :reload, :except => { :no_release => true } do
    run "cd #{current_path} ; kill -s USR2 `cat tmp/pids/unicorn.pid`"
  end

  desc "Start unicorn"
  task :start, :except => { :no_release => true } do
    run "cd #{current_path} ; unicorn_rails -c config/unicorn.rb -D -E #{stage}"
  end

  desc "Stop unicorn"
  task :stop, :except => { :no_release => true } do
    run "cd #{current_path} ; kill `cat tmp/pids/unicorn.pid`"
  end    

  desc "Graceful stop unicorn"
  task :graceful_stop, :except => { :no_release => true } do
    run "cd #{current_path} ; kill -s QUIT `cat tmp/pids/unicorn.pid`"
  end

  task :restart, :roles => :app, :except => { :no_release => true } do
  end
end

task :finalize_update, :except => { :no_release => true } do
  run <<-CMD
    ln -sf #{shared_path}/database.yml #{latest_release}/config/database.yml &&
    ln -sf #{shared_path}/gitlab.yml #{latest_release}/config/gitlab.yml &&
    ln -sf #{shared_path}/unicorn.rb #{latest_release}/config/unicorn.rb &&
    ln -sf #{shared_path}/#{stage}.sqlite3 #{latest_release}/db/#{stage}.sqlite3
  CMD
end

after "deploy:create_symlink", "finalize_update"
# If you are using Passenger mod_rails uncomment this:
# namespace :deploy do
#   task :start do ; end
#   task :stop do ; end
#   task :restart, :roles => :app, :except => { :no_release => true } do
#     run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
#   end
# end