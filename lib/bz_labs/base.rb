$:.unshift(File.expand_path('./lib', ENV['rvm_path']))

require 'bz_labs/common'
require 'bundler/capistrano'
require 'rvm/capistrano'

configuration.load  do
  task(:production) do
    CAP_ENV.environment = 'production'
  end
  task(:staging) do
    CAP_ENV.environment =  'staging'
  end
end

CAP_ENV.prepare do |env|
  configuration.load do
    set :env,       env

    # Application Details
    _cset(:app_name)      { abort "Please specify the short name of the app, set :app_name, 'my_app'" }
    set(:application)     { "#{app_name}" }
    _cset(:runner)        { user }
    _cset :use_sudo,      false

    # User Details
    _cset :user,          'deployer'
    _cset(:group)         { user }

    # SCM Details
    _cset(:appdir)        { "/var/www/#{application}/#{env}" }
    set :scm,             :git
    set(:repository)      { "git@github.com:BZLabs/#{app_name}.git" }
    _cset :branch,        'master'
    _cset :deploy_via,    'remote_cache'
    set(:deploy_to)       { appdir }

    # Git settings
    ssh_options[:forward_agent]   = true

    # Deploy Details
    _cset :keep_releases, 2
    _cset :symlinks,    []
    set :rake_tasks,    []
    _cset(:rvm_ruby)      { abort "Please specify the ruby version to use, set :rvm_ruby, 'ruby-1.9.2-p290'" }
    _cset(:rvm_ruby_string) { "#{rvm_ruby}@#{app_name}" }
    set :rvm_type, :user

    # Server Details
    _cset(:server_location)        { abort "Please specify at least one server, set :server_location, 'foo.bar.com'" }
    _cset(:server_web)    { server_location }
    _cset(:server_app)    { server_location }
    _cset(:server_db)     { server_location }
    role :web, server_web
    role :app, server_app
    role :db, server_db
    _cset :port,          22

    before 'deploy:finalize_update', 'deploy:create_symlinks'
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

      namespace :assets do
        task :precompile do
          run "cd #{release_path} && bundle exec rake RAILS_ENV=#{env} RAILS_GROUPS=assets assets:precompile"
        end
      end
    end
  end
end

