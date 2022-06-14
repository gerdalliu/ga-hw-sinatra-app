# frozen_string_literal: true

require 'sinatra/base'
require 'sinatra/reloader'
require 'dotenv/load'

require_relative 'src/routes/init'
require_relative './config/environment'

map '/' do
  run HomeRoutes.new
end

map '/users' do
  run UserRoutes.new
end

map '/db' do
  run DatabaseRoutes.new
end
