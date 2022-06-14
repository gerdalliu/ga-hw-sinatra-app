require 'sinatra/base'
require 'sinatra/reloader'
require 'dotenv'

# class MainApp < Sinatra::Application

#     configure :production do
#         enable :logging #! enabled by default
#         disable :dump_errors
#     end
 

# end

Dotenv.load

require_relative 'spec/models/init'
require_relative 'spec/routes/init'
# require_relative 'helpers/init'

