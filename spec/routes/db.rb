require_relative "../controller/db"
require_relative "../../helpers/token"

class DatabaseRoutes < Sinatra::Base
    register Sinatra::Namespace

    use AuthMiddleware
    
    before do
        content_type 'application/json'
    end

    # /db/admin
    namespace '/schema' do

        post('/db') do
            
            payload = params
            payload = JSON.parse(request.body.read) unless params[:path]
            
            summary = DBController.createDatabase(payload['statement'], payload['params'])
    
            if summary[:ok]
                {msg: "Database created."}.to_json
            else
                {msg: "Could not create database.", detail: summary[:detail]}.to_json 
            end

        end
        
        #=> This lists all databases
        get('/') do
            summary = DBController.getDatabases

            if summary[:ok]
                {tables: summary[:data]}.to_json
            else
                {msg: "Could not get databases.", details: summary[:details]}.to_json 
            end

        end

        delete('/') do
            "This deletes schema with name #{params['name']}"
        end

        put('/') do
            "This should get an uploaded schema file and apply it"
        end
    end

    # /db/table
    #=> These 
    namespace '/table' do

        post('/insert') do
            #=> should 
            {msg: "This creates a DB by getting a schema file as an upload"}.to_json
        end
        
        get('/select') do
            {msg: "This gets a database with name #{params['name']}" }.to_json
        end

        delete('/delete') do
            "This deletes schema with name #{params['name']}"
        end

        put('/update') do
            "This should get an uploaded schema file and apply it"
        end
    end

    # /db/record
    #=> These 
    namespace '/record' do

        post('/insert') do
            #=> should 
            {msg: "This creates a DB by getting a schema file as an upload"}.to_json
        end
        
        get('/select') do
            puts request.env["A9_PERMISSIONS"]
            {msg: "This gets a database with name #{params['name']}" }.to_json
        end

        delete('/delete') do
            "This deletes schema with name #{params['name']}"
        end

        put('/update') do
            "This should get an uploaded schema file and apply it"
        end
    end

end