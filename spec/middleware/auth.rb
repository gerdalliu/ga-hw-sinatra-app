require 'jwt'
require 'openssl'
require 'sinatra/namespace'
require "sinatra/multi_route"
require "json"

'''
Let\'s assume that JWTs are not stored in the database, and changing users permission levels does not
require refreshing tokens.

'''
class AuthMiddleware

    def initialize(app)
        @app = app
    end

    def call(env) 
        begin

            @req = Rack::Request.new(env)

            if should_authenticate?
                authToken = env.fetch('HTTP_AUTHORIZATION')[7..-1]
                puts authToken
        
                fkey = File.read("./util/sec/pubkey")
                pubkey = OpenSSL::PKey::RSA.new(fkey)

                decoded_token = JWT.decode authToken, pubkey, false, { algorithm: 'RS256' }

                #=> To add data to the request; this modifies the `env` variable
                @req.set_header("A9_PERMISSIONS", decoded_token[0]["permissions"])
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

        @req.path.match?(/\w+admin\/*/) || @req.request_method == "DELETE"

        # && ! @req.path.match(/some user route/) 
    end
end
