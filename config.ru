# frozen_string_literal: true

require 'sinatra/base'
require 'sinatra/reloader'
require 'dotenv'

require_relative 'src/routes/init'
require_relative './config/environment'

map '/' do
  home_app = HomeRoutes.new
  run home_app
end

map '/users' do
  users_app = UserRoutes.new
  run users_app
end

map '/db' do
  db_app = DatabaseRoutes.new
  run db_app
end
