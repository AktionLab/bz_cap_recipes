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
  run_cd("RAILS_ENV=#{ENV['RAILS_ENV']} bundle exec rake #{tasks}")
end 
def write_remote_file(name, text)
  run "cd #{appdir} && mkdir -p `dirname #{name}` && if [ ! -f #{name} ]; then echo '" + text + "' >#{name}; fi"
end

def write_local_file(name, text)
  return if File.exists?(name)
  File.open(name, 'wb') {|file| file << text}
end

