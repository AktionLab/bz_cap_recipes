module BzLabs
  module Capistrano
    class Environment
      attr_accessor :environment

      def initialize
        @blocks = {}
      end

      def prepare(env = :all, &block)
        raise ArgumentError.new("Environment callback requires a block") unless block_given?
        @blocks[env] ||= []
        @blocks[env] << block
      end

      def environment=(env)
        @environment = env
        load_environment
      end

    private

      def load_environment
        raise "No Environment set" if @environment.nil?
        callbacks = []
        callbacks += @blocks[:all] unless @blocks[:all].nil?
        callbacks += @blocks[@environment] unless @blocks[@environment].nil?
        callbacks.flatten.each do |c|
          c.call(@environment)
        end
      end
    end
  end
end

CAP_ENV = BzLabs::Capistrano::Environment.new

def _cset(name, *args, &block)
  unless exists?(name)
    set(name, *args, &block)
  end
end

def configuration
  $configuration ||= Capistrano::Configuration.instance(true)
end

configuration

def run_cd(command)
  run("cd #{release_path} && #{command}")
end

def run_rake(tasks)
  run_cd("RAILS_ENV=#{env} bundle exec rake #{tasks}")
end 
def write_remote_file(name, text)
  run "cd #{appdir} && mkdir -p `dirname #{name}` && if [ ! -f #{name} ]; then echo '" + text + "' >#{name}; fi"
end

def write_local_file(name, text)
  return if File.exists?(name)
  File.open(name, 'wb') {|file| file << text}
end

