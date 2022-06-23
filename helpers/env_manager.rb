require 'json'

#! replace w/ URI package logic
# TODO: in production we should provide 'USER_DB_NAME' and 'APP_ENV' explicitly
class EnvParser
  def self.hash(password)
    BCrypt::Password.create(password) #=> returns hash for storing
  end

  def self.load_cf_env
    envs = JSON.parse(ENV['VCAP_SERVICES'])

    cf_uri = envs['postgresql']['credentials']['uri']

    # puts cf_uri.split("/")[2].split("@")[1].split(",")[0].split(":")[1]
    ENV['DB_HOST'] = cf_uri.split('/')[2].split('@')[1].split(',')[0].split(':')[0] # host
    ENV['PRIMARY_DB_NAME'] = cf_uri.split('/')[3] # database

    user_pass = cf_uri.split('/')[2].split('@')[0]

    ENV['DB_USER'] = user_pass.split(':')[0]
    ENV['DB_PASS'] = user_pass.split(':')[1]
  end
end
