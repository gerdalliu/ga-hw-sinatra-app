require_relative "../../helpers/hash"
require 'sequel'

class DBController < Sinatra::Application
    
    #=> Connect to the main database
    @@primaryDB = Sequel.postgres "postgres", user:ENV['DB_USER'], password:ENV['DB_PASS'], host:ENV['DB_HOST']

    #! params must be a list of strings
    def self.createDatabase(dbName)
        begin

            query = "CREATE DATABASE #{@@primaryDB.literal(dbName).gsub!(/^\'|\'?$/, '')}"

            @@primaryDB.execute(query)

            {:ok => true}
        rescue => err
            {:ok => false, :details => err.message}
        end
    end

    def self.getDatabases
        begin
            res = @@primaryDB["SELECT datname FROM pg_database"]

            data = Array.new

            res.each {|r| data.append(r[:datname])}

            {:ok => true, :data => data}

        rescue => err
            {:ok => false, :details => err.message}

            logger.info err.backtrace
        end
    end
    
    def self.dropDatabase(dbName)
        begin
            query = "DROP DATABASE #{@@primaryDB.literal(dbName).gsub!(/^\'|\'?$/, '')}"

            @@primaryDB.execute(query)

            {:ok => true}
        rescue => err
            {:ok => false, :details => err.message}
        end
    end

    def self.renameDatabase(oldName, newName)
        begin

            res = @@primaryDB["SELECT datname FROM pg_database"]

            dbExists = res.any? do |r|
                r[:datname] == oldName
            end

            puts dbExists
            unless dbExists
                return {:ok => false, :details => "database not found"}
            end

            query = "ALTER DATABASE #{@@primaryDB.literal(oldName).gsub!(/^\'|\'?$/, '')} RENAME TO #{@@primaryDB.literal(newName).gsub!(/^\'|\'?$/, '')}"

            @@primaryDB.execute(query)
            
            {:ok => true}
        rescue => err
            {:ok => false, :details => err.message}
        end
    end
end

