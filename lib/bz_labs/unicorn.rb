require 'bz_labs/common'

configuration.load do
  config_file = <<-EOF
app_path = "#{appdir}"
worker_processes #{ENV['RAILS_ENV'] == 'production' ? 4 : 1}
user '#{user}', '#{group}'
working_directory "#{appdir}/current"
listen "/tmp/unicorn-#{app_name}_#{ENV['RAILS_ENV']}.sock", :backlog => 64
timeout 30
pid "#{appdir}/shared/pids/unicorn.pid"
stderr_path "#{appdir}/shared/log/unicorn-stderr.log"
stdout_path "#{appdir}/shared/log/unicorn-stdout.log"

preload_app true

GC.respond_to?(:copy_on_write_friendly=) and
  GC.copy_on_write_friendly = true

before_fork do |server, worker|
  defined?(ActiveRecord::Base) and
    ActiveRecord::Base.connection.disconnect!
end

after_fork do |server, worker|
  defined?(ActiveRecord::Base) and
    ActiveRecord::Base.establish_connection
end

EOF
  
  control_script = <<-EOF
#!/bin/sh

set -e

test -z "$ENV['RAILS_ENV']" && ENV['RAILS_ENV']=production

CMD="bundle exec unicorn -c config/unicorn.rb -E $RAILS_ENV -D"
export PID=tmp/pids/unicorn.pid
export OLD_PID="$PID.oldbin"

haz_proc () {
  if [ -s "$1" ]; then
    ps `cat $1` 2>&1 >/dev/null
  else
    return 1
  fi
}

start () {
  if haz_proc "$PID"; then
    echo "Already Running"
    exit 0
  fi

  echo "Starting"
  $CMD
}

stop () {
  if haz_proc "$PID"; then
    echo "Stopping Process"
    kill -QUIT `cat $PID`
  else
    echo "Not Running"
  fi
}

restart () {
  if haz_proc "$PID"; then
    echo "Triggering Restart"
    kill -USR2 `cat $PID`
    sleep 15
    if haz_proc "$OLD_PID"; then
      echo "Restart in progress"
      exit 0
    else
      echo >&2 "Failed to restart, performing hard stop/start"
      stop
      sleep 5
      start
    fi
  else
    start
  fi
}

case $1 in
  start) start ;;
  stop) stop ;;
  restart) restart ;;
  *) echo >&2 "Usage: $0 <start|stop|restart>" && exit 1 ;;
esac

EOF

  symlinks << 'config/unicorn.rb'

  after 'deploy:setup', 'unicorn:setup'

  namespace :unicorn do
    task :setup do
      write_remote_file('shared/config/unicorn.rb', config_file)
      write_local_file('script/unicorn', control_script)
      `chmod +x script/unicorn`
    end
  end

  namespace :deploy do
    %w(start stop restart).each do |action|
      task action do
        run("cd #{current_path} && RAILS_ENV=#{ENV['RAILS_ENV']} script/unicorn #{action}")
      end
    end
  end
end

