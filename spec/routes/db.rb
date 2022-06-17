require 'sinatra'
require 'rack'

require_relative "../controller/db"
require_relative "../../helpers/token"

class DatabaseRoutes < Sinatra::Base
    register Sinatra::Namespace

    use AuthMiddleware
    
    before do
        content_type 'application/json'
    end

    configure :development do
        Sinatra::Application.reset!
        use Rack::Reloader
    end

    # /db/schema
    namespace '/schema' do

        post('') do
            payload = params
            payload = JSON.parse(request.body.read) unless params[:path]
            
            unless payload.has_key?("dbname") &&  !(payload["dbname"].empty?)
                return {msg: "Could not create database.", detail: "DB name not provided"}.to_json 
            end

            summary = DBController.createDatabase(payload['dbname'])
    
            if summary[:ok]
                {msg: "Database created."}.to_json
            else
                {msg: "Could not create database.", detail: summary[:detail]}.to_json 
            end
        end
        
        #=> This lists all databases
        get('') do
            summary = DBController.getDatabases

            if summary[:ok]
                {tables: summary[:data]}.to_json
            else
                {msg: "Could not get databases.", details: summary[:details]}.to_json 
            end

        end

        delete('') do

            puts "RUNNING"
            
            unless params.has_key?("dbname") &&  !(params["dbname"].empty?)
                return {msg: "Could not delete database.", detail: "DB name not provided"}.to_json 
            end

            summary = DBController.dropDatabase(params["dbname"])
    
            if summary[:ok]
                {msg: "Database deleted."}.to_json
            else
                {msg: "Could not drop database.", detail: summary[:detail]}.to_json 
            end
        end

        #! only allows renaming
        put('') do

            payload = params
            payload = JSON.parse(request.body.read) unless params[:path]
            
            unless payload.has_key?("dbname") &&  !(payload["dbname"].empty?)
                return {msg: "Could not update database.", detail: "DB name not provided"}.to_json 
            end

            summary = Hash.new

            if payload.has_key?("rename_to")
                unless payload.has_key?("rename_to")
                    return {msg: "Could not rename database.", detail: "New name not provided"}.to_json 
                end
                summary = DBController.renameDatabase(payload['dbname'], payload['rename_to'])
            end
            
            #=> can add other update procedures here

            if summary[:ok]
                {msg: "Database schema updated."}.to_json
            else
                {msg: "Could not update database.", detail: summary[:details]}.to_json 
            end
        end
    end

    # /db/table
    #TODO how to connect to a specific database from the main connection?
    namespace '/table' do

        post('/') do
            #=> should 
            payload = params
            payload = JSON.parse(request.body.read) unless params[:path]
            
            unless payload.has_key? 'statement' && ! payload['statement'].empty?
                return {msg: "Could not create table.", detail: "Query statement not provided"}.to_json 
            end

            unless payload.has_key? 'values' && payload['values'].kind_of?(Array) && payload['values'].length > 0
                return {msg: "Could not create table.", detail: "Binding values must be provided as arrays"}.to_json 
            end

            summary = DBController.createDatabase(payload['statement'], *payload['values'])
    
            if summary[:ok]
                {msg: "Database created."}.to_json
            else
                {msg: "Could not create table.", detail: summary[:detail]}.to_json 
            end
        end
        
        get('/') do
            {msg: "This gets a database with name #{params['name']}" }.to_json
        end

        delete('/') do
            "This deletes schema with name #{params['name']}"
        end

        put('/') do
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