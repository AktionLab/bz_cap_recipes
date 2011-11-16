require 'capistrano/bz_labs/comon'
require 'capistrano/ext/multistage'
require 'bundler/capistrano'
require 'rvm/capistrano'


configuration.load do
  # User Details
  _cset :user,          'deployer'
  _cset(:group)         { user }

  # Application Details
  _cset(:app_name)      { abort "Please specify the short name of the app, set :app_name, 'my_app'" }
  _cset(:rails_env)     { abort "Please specify the rails environment, set :rails_env, 'production'" }
  set(:application)     { "#{app_name}" }
  _cset(:runner)        { user }
  _cset :use_sudo,      false

  # SCM Details
  _cset(:appdir)        { "/var/www/#{application}/#{rails_env}" }
  _cset :scm,           :git
  set(:repository)      { "git@github.com:BZLabs/#{app_name}.git" }
  _cset :branch,        'master'
  _cset :deploy_via,    'remote_cache'
  set(:deploy_to)       { appdir }

  # Git settings
  ssh_options[:forward_agent]   = true

  # Deploy Details
  _cset :keep_releases, 2
  _cset :symlinks,      []
  _cset :rake_tasks,    []
  _cset :rvm_ruby_string, "1.9.2-p290@#{app_name}"
  set :rvm_type, :user
  _cset :stages, %w(production staging)

  after 'deploy:update_code', 'deploy:create_symlinks'
  before 'deploy:symlink', 'deploy:run_rake_tasks'
  after 'deploy', 'deploy:cleanup'

  namespace :deploy do
    task :create_symlinks do
      run(symlinks.map do |link|
        "rm -rf #{release_path}/#{link} && ln -nfs #{shared_path}/#{link} #{release_path}/#{link}"
      end.join(' && ')) unless symlinks.empty?
    end

    task :run_rake_tasks do
      run_rake(rake_tasks.join(' ')) unless rake_tasks.empty?
    end
  end
end

