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
    namespace '/table' do

        post('') do

            payload = params
            payload = JSON.parse(request.body.read) unless params[:path]
            
            unless payload.has_key?("dbname") && ! (payload["dbname"].empty?)
                return {msg: "Could not create table.", detail: "No database target provided"}.to_json 
            end

            unless payload.has_key?('name') && ! (payload['name'].empty?)
                return {msg: "Could not create table.", detail: "Table name not provided"}.to_json 
            end

            unless payload.has_key?('columns') && ! (payload['columns'].empty?)
                return {msg: "Could not create table.", detail: "No columns provided"}.to_json 
            end

            summary = DBController.createTable(payload['dbname'], payload['name'], payload['columns'])
    
            if summary[:ok]
                {msg: "Table created."}.to_json
            else
                {msg: "Could not create table.", details: summary[:details]}.to_json 
            end
        end
        
        get('') do
            unless params.has_key?("dbname") && ! (params["dbname"].empty?)
                return {msg: "Could not get table info.", detail: "No database target provided"}.to_json 
            end

            unless params.has_key?('name') && ! (params['name'].empty?)
                return {msg: "Could not get table info.", detail: "Table name not provided"}.to_json 
            end

            summary = DBController.getTableDescription(params['dbname'], params['name'])

            if summary[:ok]
                {params['dbname'] => summary[:info]}.to_json
            else
                {msg: "Could not get table info.", details: summary[:details]}.to_json 
            end
           
        end

        delete('') do
            unless params.has_key?("dbname") && ! (params["dbname"].empty?)
                return {msg: "Could not delete table.", detail: "No database target provided"}.to_json 
            end

            unless params.has_key?('name') && ! (params['name'].empty?)
                return {msg: "Could not delete table.", detail: "Table name not provided"}.to_json 
            end

            summary = DBController.dropTable(params['dbname'], params['name'])
    
            if summary[:ok]
                {msg: "Table dropped."}.to_json
            else
                {msg: "Could not drop table.", details: summary[:detail]}.to_json 
            end
        end

        put('') do
            payload = params
            payload = JSON.parse(request.body.read) unless params[:path]
            
            unless payload.has_key?("dbname") && ! (payload["dbname"].empty?)
                return {msg: "Could not alter table.", detail: "No database target provided"}.to_json 
            end

            unless payload.has_key?('name') && ! (payload['name'].empty?)
                return {msg: "Could not alter table.", detail: "Table name not provided"}.to_json 
            end

            unless payload.has_key?('column_details') && ! (payload['column_details'].empty?)
                return {msg: "Could not alter table.", detail: "No column info provided"}.to_json 
            end
            
            unless payload.has_key?('operation') && ! (payload['operation'].empty?)
                return {msg: "Could not alter table.", detail: "No operation specified"}.to_json 
            end

            summary = DBController.alterTable(payload['dbname'], payload['name'], payload['column_details'], payload['operation'])
    
            if summary[:ok]
                {msg: "Table updated."}.to_json
            else
                {msg: "Could not update table schema.", details: summary[:details]}.to_json 
            end
        end
    end

    #TODO create the basic query string endpoints first.
    # /db/record
    namespace '/record' do

        post('/insert') do
            #=> should 
            {msg: "This creates a DB by getting a schema file as an upload"}.to_json
        end
        
        ## simple selects, not grouping or limiting/paginating
        post('/select') do
            
            payload = params
            payload = JSON.parse(request.body.read) unless params[:path]
            
            unless payload.has_key?("dbname") && ! (payload["dbname"].empty?)
                return {msg: "Could not perform select.", detail: "No database target provided"}.to_json 
            end

            unless payload.has_key?('name') && ! (payload['name'].empty?)
                return {msg: "Could not perform select.", detail: "Table name not provided"}.to_json 
            end

            unless payload.has_key?('columns') && ! (payload['name'].empty?)
                return {msg: "Could not perform select.", detail: "No column names provided"}.to_json 
            end

            if payload.has_key?('conditions') && (payload['conditions'].empty?)
                return {msg: "Could not perform select.", detail: "Conditions can't be present and empty"}.to_json 
            end

            summary = DBController.select(payload['dbname'], payload['name'], payload['columns'], payload['conditions'])
    
            if summary[:ok]
                {data: summary[:data]}.to_json
            else
                {msg: "Could not perform select.", details: summary[:details]}.to_json 
            end

        end

        delete('/delete') do
            "This deletes rows"
        end

        put('/update') do
            "This updates rows"
        end

       
    end

end