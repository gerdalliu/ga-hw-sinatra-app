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

    ############################################################################
    def self.createTable(db, name, columns)
        
        begin
            tmpConnection = Sequel.postgres db, user:ENV['DB_USER'], password:ENV['DB_PASS'], host:ENV['DB_HOST']

            typesError = false
            
            tmpConnection.create_table(name.strip.downcase.gsub(/\s+/, "_").to_sym) do

                pkeyCols = Array.new

                columns.each do |col|

                    ## each col contains name, primary_key flag and a type field.
                    ## We could include more constraints, but it is not necessary

                    symbolicName = col["name"].strip.to_sym
                    
                    isPkey = false
                    colType = String
                    
                    if col.has_key?("primary_key") && col["primary_key"] == true
                        pkeyCols.append(symbolicName)
                        next
                    end

                    unless col.has_key?("type") && ! col["type"].empty?
                        typesError = true
                        return
                    end

                    column symbolicName, col["type"]
                end

                primary_key *pkeyCols
            end

            if typesError 
                raise StandardError("malformed type expression")
            end

            {:ok => true}
        rescue => err
            {:ok => false, :details => err.message} 
        end
        
    end

    def self.dropTable(db, name)

        begin
            tmpConnection = Sequel.postgres db, user:ENV['DB_USER'], password:ENV['DB_PASS'], host:ENV['DB_HOST']
            tmpConnection.drop_table(name.strip.downcase.gsub(/\s+/, "_").to_sym)  
            {:ok => true}

        rescue => err
            {:ok => false, :details => err.message} 
        end
    end

   
    def self.getTableDescription(db, name)

        begin
            query = "select column_name, data_type, character_maximum_length, column_default, is_nullable from INFORMATION_SCHEMA.COLUMNS where table_name = ?"
            
            tmpConnection = Sequel.postgres db, user:ENV['DB_USER'], password:ENV['DB_PASS'], host:ENV['DB_HOST']

            desc = tmpConnection[query, name.strip.downcase.gsub(/\s+/, "_")]
            
            items = Array.new

            desc.each do |rec| 
                puts rec
                items.append(rec)
            end
        
            puts items
            
            {:ok => true, :info => items}

        rescue => err
            puts err.backtrace
            {:ok => false, :details => err.message} 
        end
    end

    def self.alterTable(db, name, column_details, operation)

        begin
            tmpConnection = Sequel.postgres db, user:ENV['DB_USER'], password:ENV['DB_PASS'], host:ENV['DB_HOST']

            symbolicTableName = name.strip.downcase.gsub(/\s+/, "_").to_sym

            miscError

            case operation.upcase
            when "ADD"
                tmpConnection.alter_table(symbolicTableName) do

                    column_details.each do |col| 
                        symbolicName = col["name"].strip.to_sym
                        add_column symbolicName, col["type"]
                    end
                end
            when "DROP"

                tmpConnection.alter_table(symbolicTableName) do

                    column_details.each do |col| 
                        symbolicName = col.strip.to_sym
                        drop_column symbolicName
                    end
                end

            when "RENAME"
                tmpConnection.alter_table(symbolicTableName) do
                    column_details.each do |col| 
                        oldSymbolicName = col["old"].strip.to_sym
                        newSymbolicName = col["new"].strip.to_sym
                        add_column oldSymbolicName, newSymbolicName
                    end

                end                
            when "PKEY"

                pkeys = Array.new
                column_details["columns"].each do |col|
                    symbolicName = col["name"].strip.to_sym
                    pkeys.append(symbolicName)
                end

                add_primary_key *pkeys
            else
                raise StandardError "unknown operation"
            end      
            
            raise StandardError "malformed column details" if miscError 

            {:ok => true}
        rescue => err
            {:ok => false, :details => err.message} 
        end
        
    end
end

