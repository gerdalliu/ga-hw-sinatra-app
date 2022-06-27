require 'json'

class EnvParser
  def self.load_cf_env
    envs = JSON.parse(ENV['VCAP_SERVICES'])
    creds = envs[envs.keys.first][0]['credentials']

    ENV['DB_HOST'] = creds['host']
    ENV['PRIMARY_DB_NAME'] = creds['name']
    ENV['DB_USER'] = creds['username']
    ENV['DB_PASS'] = creds['password']
  end
end
