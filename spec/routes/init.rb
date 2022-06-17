require 'sinatra/base'
require 'sinatra/namespace'
require 'json'

require_relative '../middleware/auth'

require_relative 'home'
require_relative 'users'
require_relative 'db'