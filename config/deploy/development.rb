set :config, config_yaml['development']

set :deploy_to, config['deploy_to']
set :current_dir, config['current_dir']
set :rails_env, config['rails_env']

if ENV['CAP_USER']
  set :user, ENV['CAP_USER']
elsif ENV['user']
  set :user, ENV['user']
else
  set :user, config['user']
end

# if config['password']
#   set :password, config['password']
# end

if config['branch']
  set :branch, config['branch']
end
set :repository, config['repo']
server config['server'], :app, :web, :db, :primary => true

set :default_environment, {
  'PATH' => "#{config['ruby_path']}/:$PATH"
}