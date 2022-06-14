require 'jwt'
require 'openssl'
require 'sinatra/namespace'
class AdminController < Sinatra::Application

    #! Do we even need namespaces?
    namespace '/admin', :provides => ['json'] do

        #TODO add authentication
        
        get('/authenticate') do
    
            # rsa_key = OpenSSL::PKey::RSA.generate 2048 #! this is the private key
            # rsa_public = rsa_key.public_key
    
            rsa_key = OpenSSL::PKey::RSA.new(File.read("./util/sec/privkey"))
            
            exp = Time.now.to_i() + 4 * 3600
            payload = { permissions: 'ADMIN', exp: exp }
    
            #TODO add expiry
            JWT.encode payload, rsa_key, 'RS256' #=> RETURNS TOKEN
    
        end
        
        #TODO add middleware for authentication
        get('/health') do
    
            authToken = env.fetch('HTTP_AUTHORIZATION')[7..-1]
    
            fkey = File.read("./util/sec/pubkey")
            pubkey = OpenSSL::PKey::RSA.new(fkey)
    
            begin
                decoded_token = JWT.decode authToken, pubkey, true, { algorithm: 'RS256' }
    
                "Alive and digesting:\n\n #{decoded_token}"
    
            rescue JWT::ExpiredSignature => ExpiredSignature
    
                puts "EXPIRED TOKEN: #{err.message}"
                # Handle expired token, e.g. logout user or deny access
                err.message
            rescue => err
                puts "ERR: #{err}"
    
                err.message
            end
    
        end
    
        post('/db') do
            "This creates a DB by getting a schema file as an upload"
        end
    
        get('/db') do
            "This gets a database with name #{params['name']}"
        end
    
        delete('/db') do
            "This deletes schema with name #{params['name']}"
        end
    
        put('/db') do
            "This should get an uploaded schema file and apply it"
        end
    
    end
end
