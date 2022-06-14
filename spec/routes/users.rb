require_relative "../controller/user"
require_relative "../../helpers/token"

class UserRoutes < Sinatra::Base
 
    register Sinatra::Namespace

    use AuthMiddleware

    before do
        content_type 'application/json'
    end

    configure :development do
        enable :logging
    end
    
    get('/login') do
        
        payload = { permissions: 'ADMIN' } #! or USER, depending on credentials

        JWTUtil.createJWT(payload)
    end

    get('/:id') do
        UserController.getOne(params['id'])
    end

    namespace '/admin' do

        #~~   namespace '/admin', :provides => ['json'] do
        
        post('/db') do
            {msg: "This creates a DB by getting a schema file as an upload"}.to_json
        end

        get('/db') do
            {msg: "This gets a database with name #{params['name']}" }.to_json
        end

        delete('/db') do
            "This deletes schema with name #{params['name']}"
        end

        put('/db') do
            "This should get an uploaded schema file and apply it"
        end
        
        get('/login') do
            "Admin Auth"
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
