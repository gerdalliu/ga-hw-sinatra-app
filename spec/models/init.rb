require 'sequel'

DB = Sequel.postgres ENV['USER_DB_NAME'], user: ENV['DB_USER'], password: ENV['DB_PASS'], host: ENV['DB_HOST']

require_relative 'user'
