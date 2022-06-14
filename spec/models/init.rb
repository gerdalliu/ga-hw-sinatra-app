require 'activerecord'

DB = Sequel.postgres 'yolodob', user:'gerd', password:'gerd123', host:'localhost'

require_relative 'user'
