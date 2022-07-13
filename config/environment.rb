require_relative '../helpers/env_manager'

if ENV['APP_ENV'] == 'development'
  Dotenv.load
else
  # TODO: test this
  EnvParser.load_cf_env
end
