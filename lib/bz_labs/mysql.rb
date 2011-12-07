require 'bz_labs/common'
require 'active_support'

configuration.load do
  _cset :mysql_password, SecureRandom.base64(20)
  symlinks << 'config/database.yml'
  rake_tasks << 'db:migrate'

  config_file = <<-EOF
#{ENV['RAILS_ENV']}:
  adapter: mysql2
  database: #{app_name}_#{ENV['RAILS_ENV']}
  username: #{user}_#{ENV['RAILS_ENV']}
  password: #{mysql_password}
  EOF
  
  after 'deploy:setup', 'db:setup'

  namespace :db do
    task :setup do
      write_remote_file('shared/config/database.yml', config_file)
      run %Q(echo "CREATE DATABASE #{app_name}_#{ENV['RAILS_ENV']};" | sudo su -c mysql)
      run %Q(echo "CREATE USER '#{user}_#{ENV['RAILS_ENV']}'@'localhost' IDENTIFIED BY '#{mysql_password}';" | sudo su -c mysql; true)
      run %Q(echo "GRANT ALL ON #{app_name}_#{ENV['RAILS_ENV']}.* TO '#{user}'@'localhost';" | sudo su -c mysql)
      run %Q(echo "FLUSH PRIVILEGES;" | sudo su -c mysql)
    end
  end
end

