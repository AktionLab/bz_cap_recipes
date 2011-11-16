def _cset(name, *args, &block)
  unless exists?(name)
    set(name, *args, &block)
  end
end

def configuration
  Capistrano::Configuration.respond_to?(:instance) ?
    Capistrano::Configuration.instance(:must_exist) :
    Capistrano.configuration(:must_exist)
end

def run_cd(command)
  run("cd #{release_path} && #{command}")
end

def run_rake(tasks)
  run_cd("RAILS_ENV=#{rails_env} bundle exec rake #{tasks}")
end

def write_remote_config(name, text)
  run "cd #{appdir} && mkdir -p `dirname #{name}` && if [ ! -f #{name} ]; then echo '#{text}' >#{name}; fi"
end

def write_local_config(name, text)
  return if File.exists("#{Rails.root.to_s}/#{name}")
  File.open("#{Rails.root.to_s}/#{name}", 'wb') {|file| file << text}
end

