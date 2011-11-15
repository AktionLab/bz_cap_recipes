require 'capistrano/bz_labs/comon'

configuration = Capistrano::Configuration.respond_to?(:instance) ?
  Capistrano::Configuration.instance(:must_exist) :
  Capistrano.configuration(:must_exist)

configuration.load do
  # User Details
  _cset :user,          'deployer'
  _cset(:group)         { user }

  # Application Details
  _cset(:app_name)      { abort "Please specify the short name of the app, set :app_name, 'my_app'" }
  _cset(:rails_env)     { abort "Please specify the rails environment, set :rails_env, 'production'" }
  set(:application)     { "#{app_name}.bz-labs.com" }
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
end

