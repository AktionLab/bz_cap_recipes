require 'bz_labs/common'

configuration.load do
  _cset :nginx_conf_dir, '/etc/nginx'

  config_file = <<-EOF
upstream #{app_name}_#{ENV['RAILS_ENV']} {
  server unix:/tmp/unicorn-#{app_name}_#{ENV['RAILS_ENV']}.sock fail_timeout=0;
}

server {
  listen 80;

  server_name #{app_name}#{ENV['RAILS_ENV'] == 'staging' ? '.staging' : ''}.bz-labs.com;
  
  root #{appdir}/current/public;
  access_log /var/log/nginx/#{app_name}_#{ENV['RAILS_ENV']}-access.log;
  error_log /var/log/nginx/#{app_name}_#{ENV['RAILS_ENV']}-error.log;

  location ~ ^/assets/ {
    expires max;
    add_header Cache-Control public;
  }

  location / {
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded_For $proxy_add_x_forwarded_for;
    proxy_set_header Host $http_host;
    proxy_redirect off;

    if (!-f $request_filename) {
      proxy_pass http://#{app_name}_#{ENV['RAILS_ENV']};
      break;
    }
  }

  error_page 404 /404.html;
  error_page 500 502 503 504 /500.html;
}

EOF
  
  after 'deploy:setup', 'nginx:setup'
  before 'deploy:restart', 'nginx:symlink'
  after 'nginx:symlink', 'nginx:reload'

  namespace :nginx do
    task :setup do
      write_local_file("config/nginx-#{ENV['RAILS_ENV']}.conf", config_file)
    end

    task :symlink do
      run "sudo rm -rf #{nginx_conf_dir}/sites-enabled/#{app_name}-#{ENV['RAILS_ENV']} && sudo ln -nfs #{appdir}/current/config/nginx-#{ENV['RAILS_ENV']}.conf #{nginx_conf_dir}/sites-enabled/#{app_name}-#{ENV['RAILS_ENV']}"
    end

    %w(start stop restart reload).each do |action|
      task action do
        run "sudo service nginx #{action}"
      end
    end
  end
end

