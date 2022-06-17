require_relative "../../helpers/hash"
require 'sequel'

class DBController < Sinatra::Application
    
    #=> Connect to the main database
    @@primaryDB = Sequel.postgres "postgres", user:ENV['DB_USER'], password:ENV['DB_PASS'], host:ENV['DB_HOST']
    
    #! params must be a list of strings
    def self.createDatabase (query, params)

        begin
            if params.empty?
                @@primaryDB[query]
            else
                @@primaryDB[query, *params]
            end

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

            puts err.backtrace
        end
    end
    
end

