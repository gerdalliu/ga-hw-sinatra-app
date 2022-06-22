require_relative '../helpers/env_manager'

puts ENV['APP_ENV']

if ENV['APP_ENV'] == "development"
  Dotenv.load
else
    EnvParser.load_cf_env
end

