require 'bz_labs/common'
require 'active_support'

CAP_ENV.prepare do |env|
  configuration.load do
    _cset :mysql_password, SecureRandom.base64(20)
    symlinks << 'config/database.yml'
    rake_tasks << 'db:migrate'

    config_file = <<-EOF
  #{env}:
    adapter: mysql2
    database: #{app_name}_#{env}
    username: #{user}_#{env}
    password: #{mysql_password}
    EOF
    
    after 'deploy:setup', 'db:setup'

    mysql_cmd = %Q(sudo su -c mysql)
    create_database  = %Q(echo "CREATE DATABASE #{app_name}_#{env};" | #{mysql_cmd})
    create_user      = %Q(echo "CREATE USER '#{user}_#{env}'@'localhost' IDENTIFIED BY '#{mysql_password}';" | #{mysql_cmd}; true)
    grant            = %Q(echo "GRANT ALL ON #{app_name}_#{env}.* TO '#{user}'@'localhost';" | #{mysql_cmd})
    flush_privileges = %Q(echo "FLUSH PRIVILEGES;" | #{mysql_cmd})

    namespace :db do
      task :setup do
        write_remote_file('shared/config/database.yml', config_file)
        run create_database
        run create_user
        run grant
        run flush_privileges
      end
    end
  end
end
