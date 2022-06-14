require_relative "../controller/user"
require_relative "../../helpers/token"

'''
Let\'s assume that Users cannot update their accounts themselves, only admins can. 

'''
class UserRoutes < Sinatra::Base
 
    register Sinatra::Namespace

    use AuthMiddleware

    before do
        content_type 'application/json'
    end

    configure :development do
        enable :logging
    end
    
    #=> Login
    get('/login') do

        # payload = params
        # payload = JSON.parse(request.body.read) unless params["path"]

        summary = UserController.auth(params['email'], params['password'])

        if summary[:ok]
            tokenPayload = { permissions: summary[:permissions] } #! ADMIN or USER

            {"token": JWTUtil.createJWT(tokenPayload)}.to_json
        else
            halt 409, "Login failed!"
        end
    end

    post('/register') do
        payload = params
        payload = JSON.parse(request.body.read) unless params[:path]

        logger.info "Creating user with #{payload[:meta]}"

        #TODO check if email is already taken!
        summary = UserController.createOne(payload)

        if summary[:ok]

            if summary[:user][:isadmin]
                tokenPayload = { permissions: 'ADMIN' } 
            else
                tokenPayload = { permissions: 'USER' }
            end

            token = JWTUtil.createJWT(tokenPayload)

            {user: summary[:user], msg: "User created.", token: token}.to_json
        else
            {msg: "Could not create user.", details: summary[:detail]}.to_json 
        end
    end

    delete('/') do
        
        if request.env["A9_PERMISSIONS"] != "USER"
            return {msg: "Could not delete account.", detail: "You need to log in first!"}.to_json 
        end
        
        summary = UserController.auth(params['email'], params['password'])

        if ! summary[:ok]
            return {msg: "Could not delete account.", detail: "User not found or wrong password"}.to_json 
        end

        summary = UserController.deleteOne(params['email'])

        if summary[:ok]
            {msg: "Account deleted."}.to_json
        else
            {msg: "Could not delete account."}.to_json 
        end
    end

    namespace '/admin' do

        get('/') do
            summary = UserController.getOne(params['id'])

            summary[:user] unless ! summary[:ok]
        end
    
        #TODO test thi
        post('/create') do
            payload = params
            payload = JSON.parse(request.body.read) unless params[:path]
    
            summary = UserController.createOne(payload)
    
            if summary[:ok]
                {user: summary[:user], msg: "User created."}.to_json
            else
                {msg: "Could not create user."}.to_json 
            end
        end
    
        put('/update') do
    
            payload = params
            payload = JSON.parse(request.body.read) unless params[:path]
    
            summary = UserController.updateOne(payload)
    
            if summary[:ok]
                {user: summary[:user], msg: "User updated."}.to_json
            else
                {msg: "Could not create user."}.to_json 
            end
        end
    
        delete('/:id') do
            ok = UserController.deleteOne(params['id'])
    
            if ok
                {msg: "User deleted."}.to_json 
            else
                {msg: "Could not delete user."}.to_json 
            end
        end
        #~~   namespace '/admin', :provides => ['json'] do

        #=> Schema endpoints
        #TODO
        post('/db') do
            {msg: "This creates a DB by getting a schema file as an upload"}.to_json
        end
        
        get('/db') do
            puts request.env["A9_PERMISSIONS"]
            {msg: "This gets a database with name #{params['name']}" }.to_json
        end

        delete('/db') do
            "This deletes schema with name #{params['name']}"
        end

        put('/db') do
            "This should get an uploaded schema file and apply it"
        end
        
    end
end
