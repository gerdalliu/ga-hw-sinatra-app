require 'sinatra/base'
require 'sinatra/reloader'
require 'dotenv'

Dotenv.load

require_relative 'spec/models/init'
require_relative 'spec/routes/init'
# require_relative 'helpers/init'


