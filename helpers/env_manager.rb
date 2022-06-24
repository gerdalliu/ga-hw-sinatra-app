require 'json'

class EnvParser

  def self.load_cf_env
    envs = JSON.parse(ENV['VCAP_SERVICES'])
    srvc = envs[envs.keys.first]
    cf_uri = srvc[0]['credentials']['uri']

    ENV['DB_HOST'] = cf_uri.split('/')[2].split('@')[1].split(',')[0].split(':')[0] # host
    ENV['PRIMARY_DB_NAME'] = cf_uri.split('/')[3] # database

    user_pass = cf_uri.split('/')[2].split('@')[0]

    ENV['DB_USER'] = user_pass.split(':')[0]
    ENV['DB_PASS'] = user_pass.split(':')[1]
  end
end
