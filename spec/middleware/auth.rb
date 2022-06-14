require 'jwt'
require 'openssl'
require 'sinatra/namespace'
require "sinatra/multi_route"
require "json"

class AuthMiddleware

    def initialize(app)
        @app = app
    end

    def call(env) 
        begin

            @req = Rack::Request.new(env)

            if should_authenticate?
                authToken = env.fetch('HTTP_AUTHORIZATION')[7..-1]
        
                fkey = File.read("./util/sec/pubkey")
                pubkey = OpenSSL::PKey::RSA.new(fkey)

                decoded_token = JWT.decode authToken, pubkey, true, { algorithm: 'RS256' }
                #=> To add data to the request:
                #TODO request = Rack::Response.new(env)
                #TODO request[:data] = <data>
            end
            

            #=> This is good to make sure headers are sent in response.
            status, headers, response = @app.call(env)
            headers['Content-Type']="application/json"
            
            [status, headers, response]
            
        
        rescue JWT::ExpiredSignature => err

            puts "EXPIRED TOKEN: #{err.message}"
            # Handle expired token, e.g. logout user or deny access
            
            Rack::Response.new("EXPIRED TOKEN", 402, {}).finish
        rescue => err
            puts "ERR: #{err}"

            Rack::Response.new("UNAUTHORIZED", 401, {}).finish
        end

    end
 

    def should_authenticate?
        @req.path.match?(/admin\/*/) 
        # && ! @req.path.match(/some user route/) 
    end
end
