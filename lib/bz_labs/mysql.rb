require 'capistrano/bz_labs/common'
require 'active_support'

configuration.load do
  _cset :password, SecureRandom.base64(20)
  _cset(:symlinks) { symlinks << 'config/database.yml' }
  _cset(:rake_tasks) { rake_tasks << 'db:migrate' }

  config_file <<-EOF
#{rails_env}:
  adapter: mysql
  database: #{app_name}_#{rails_env}
  encoding: unicode
  username: #{user}
  password: #{password}

EOF
  
  my_cnf_file <<-EOF
[client]
user=#{user}
password=#{password}

EOF

  after 'deploy:setup', 'db:setup'

  namespace :db do
    task :setup do
      write_remote_file('config/database.yml', config_file)
      run %Q(echo "#{my_cnf_file}" >/home/#{user}/.my.cnf)
      run %Q(echo "CREATE USER '#{user}'@'localhost' identified_by '#{password}';" | sudo su -c mysql)
      run %Q(echo "GRANT ALL ON #{app_name}_#{rails_env}.* to '#{user}'@'localhost';" | sudo su -c mysql)
      run %Q(echo "FLUSH PRIVILEGES;" | sudo su -c mysql)
    end
  end
end

