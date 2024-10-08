# frozen_string_literal: true

require 'sinatra'
require 'rack'

require_relative '../controller/db'
require_relative '../../helpers/token'

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

      unless payload.key?('dbname') && !payload['dbname'].empty?
        return {
          msg: 'Could not create database.',
          detail: 'DB name not provided'
        }.to_json
      end

      summary = DBController.create_database(payload['dbname'])

      if summary[:ok]
        { msg: 'Database created.' }.to_json
      else
        { msg: 'Could not create database.', detail: summary[:detail] }.to_json
      end
    end

    get('') do
      summary = DBController.databases

      if summary[:ok]
        { tables: summary[:data] }.to_json
      else
        { msg: 'Could not get databases.', details: summary[:details] }.to_json
      end
    end

    delete('') do
      puts 'RUNNING'

      unless params.key?('dbname') && !params['dbname'].empty?
        return {
          msg: 'Could not delete database.',
          detail: 'DB name not provided'
        }.to_json
      end

      summary = DBController.drop_database(params['dbname'])

      if summary[:ok]
        { msg: 'Database deleted.' }.to_json
      else
        { msg: 'Could not drop database.', detail: summary[:detail] }.to_json
      end
    end

    # ! only allows renaming
    put('') do
      payload = params
      payload = JSON.parse(request.body.read) unless params[:path]

      unless payload.key?('dbname') && !payload['dbname'].empty?
        return {
          msg: 'Could not update database.',
          detail: 'DB name not provided'
        }.to_json
      end

      summary = {}

      if payload.key?('rename_to')
        unless payload.key?('rename_to')
          return {
            msg: 'Could not rename database.',
            detail: 'New name not provided'
          }.to_json
        end

        summary = DBController.rename_database(payload['dbname'], payload['rename_to'])
      end

      if summary[:ok]
        { msg: 'Database schema updated.' }.to_json
      else
        { msg: 'Could not update database.', detail: summary[:details] }.to_json
      end
    end
  end

  # /db/table
  namespace '/table' do
    post('') do
      payload = params
      payload = JSON.parse(request.body.read) unless params[:path]

      unless payload.key?('dbname') && !payload['dbname'].empty?
        return { msg: 'Could not create table.', detail: 'No database target provided' }.to_json
      end

      unless payload.key?('name') && !payload['name'].empty?
        return {
          msg: 'Could not create table.',
          detail: 'Table name not provided'
        }.to_json
      end

      unless payload.key?('columns') && !payload['columns'].empty?
        return {
          msg: 'Could not create table.',
          detail: 'No columns provided'
        }.to_json
      end

      summary = DBController.create_table(payload['dbname'], payload['name'], payload['columns'])

      if summary[:ok]
        { msg: 'Table created.' }.to_json
      else
        { msg: 'Could not create table.', details: summary[:details] }.to_json
      end
    end

    get('') do
      unless params.key?('dbname') && !params['dbname'].empty?
        return { msg: 'Could not get table info.', detail: 'No database target provided' }.to_json
      end

      unless params.key?('name') && !params['name'].empty?
        return {
          msg: 'Could not get table info.',
          detail: 'Table name not provided'
        }.to_json
      end

      summary = DBController.get_table_description(params['dbname'], params['name'])

      if summary[:ok]
        { params['dbname'] => summary[:info] }.to_json
      else
        { msg: 'Could not get table info.', details: summary[:details] }.to_json
      end
    end

    delete('') do
      unless params.key?('dbname') && !params['dbname'].empty?
        return { msg: 'Could not delete table.', detail: 'No database target provided' }.to_json
      end

      unless params.key?('name') && !params['name'].empty?
        return {
          msg: 'Could not delete table.',
          detail: 'Table name not provided'
        }.to_json
      end

      summary = DBController.drop_table(params['dbname'], params['name'])

      if summary[:ok]
        { msg: 'Table dropped.' }.to_json
      else
        { msg: 'Could not drop table.', details: summary[:detail] }.to_json
      end
    end

    put('') do
      payload = params
      payload = JSON.parse(request.body.read) unless params[:path]

      unless payload.key?('dbname') && !payload['dbname'].empty?
        return { msg: 'Could not alter table.', detail: 'No database target provided' }.to_json
      end

      unless payload.key?('name') && !payload['name'].empty?
        return {
          msg: 'Could not alter table.',
          detail: 'Table name not provided'
        }.to_json
      end

      unless payload.key?('column_details') && !payload['column_details'].empty?
        return { msg: 'Could not alter table.', detail: 'No column info provided' }.to_json
      end

      unless payload.key?('operation') && !payload['operation'].empty?
        return { msg: 'Could not alter table.', detail: 'No operation specified' }.to_json
      end

      summary = DBController.alter_table(
        payload['dbname'],
        payload['name'],
        payload['column_details'],
        payload['operation']
      )

      if summary[:ok]
        { msg: 'Table updated.' }.to_json
      else
        { msg: 'Could not update table schema.', details: summary[:details] }.to_json
      end
    end
  end

  # /db/record
  namespace '/record' do
    post('/insert') do
      payload = params
      payload = JSON.parse(request.body.read) unless params[:path]

      unless payload.key?('dbname') && !payload['dbname'].empty?
        return { msg: 'Could not perform INSERT.', detail: 'No database target provided' }.to_json
      end

      unless payload.key?('name') && !payload['name'].empty?
        return {
          msg: 'Could not perform INSERT.',
          detail: 'Table name not provided'
        }.to_json
      end

      unless payload.key?('input') && !payload['input'].empty?
        return { msg: 'Could not perform INSERT.', detail: 'No column inputs specified' }.to_json
      end

      summary = DBController.insert_record(payload['dbname'], payload['name'], payload['input'])

      if summary[:ok]
        { msg: 'Record inserted.' }.to_json
      else
        { msg: 'Could not perform insert.', details: summary[:details] }.to_json
      end
    end

    post('/select') do
      payload = params
      payload = JSON.parse(request.body.read) unless params[:path]

      unless payload.key?('dbname') && !payload['dbname'].empty?
        return { msg: 'Could not perform SELECT.', detail: 'No database target provided' }.to_json
      end

      unless payload.key?('name') && !payload['name'].empty?
        return {
          msg: 'Could not perform SELECT.',
          detail: 'Table name not provided'
        }.to_json
      end

      unless payload.key?('columns') && !payload['name'].empty?
        return {
          msg: 'Could not perform SELECT.',
          detail: 'No column names provided'
        }.to_json
      end

      if payload.key?('where') && payload['where'].empty?
        return {
          msg: 'Could not perform SELECT.',
          detail: "Conditions can't be both present and empty"
        }.to_json
      end

      if payload.key?('lit_where') && payload['lit_where'].empty?
        return {
          msg: 'Could not perform SELECT.',
          detail: "Conditions can't be both present and empty"
        }.to_json
      end

      summary = DBController.select(
        payload['dbname'],
        payload['name'],
        payload['columns'],
        payload['where'],
        payload['lit_where']
      )

      if summary[:ok]
        { data: summary[:data] }.to_json
      else
        { msg: 'Could not perform select.', details: summary[:details] }.to_json
      end
    end

    delete('/delete') do
      unless params.key?('dbname') && !params['dbname'].empty?
        return {
          msg: 'Could not perform DELETE.',
          detail: 'No database target provided'
        }.to_json
      end

      unless params.key?('name') && !params['name'].empty?
        return {
          msg: 'Could not perform DELETE.',
          detail: 'Table name not provided'
        }.to_json
      end

      unless params.key?('id') && !params['id'].empty?
        return {
          msg: 'Could not perform DELETE.',
          detail: 'No database target provided'
        }.to_json
      end

      summary = DBController.delete_record(
        params['dbname'],
        params['name'],
        params['id']
      )

      if summary[:ok]
        { msg: 'Record deleted.' }.to_json
      else
        { msg: 'Could not perform DELETE.', details: summary[:details] }.to_json
      end
    end
  end
end
