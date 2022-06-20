# frozen_string_literal: true

require 'sinatra/base'
require 'sinatra/reloader'
require 'dotenv'

Dotenv.load

require_relative 'src/models/init'
require_relative 'src/routes/init'
# require_relative 'helpers/init'
