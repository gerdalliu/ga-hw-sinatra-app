# frozen_string_literal: true

require_relative '../../helpers/hash'
require 'sequel'

class DBController < Sinatra::Application
  def self.primary_db
    unless defined? @PDB
      @pdb = Sequel.postgres ENV['PRIMARY_DB_NAME'],
                             user: ENV['DB_USER'],
                             password: ENV['DB_PASS'],
                             host: ENV['DB_HOST']
    end

    @pdb
  end

  def self.admin_db
    unless defined? @PDB
      @pdb = Sequel.postgres 'postgres',
                             user: ENV['ADMIN_USER'],
                             password: ENV['ADMIN_PASS'],
                             host: ENV['DB_HOST']
    end

    @pdb
  end

  def self.create_database(db_name)
    query = "CREATE DATABASE #{db_name.gsub!(/^'|'?$/, '')}"

    primary_db.execute(query)

    { ok: true }
  rescue StandardError => e
    { ok: false, details: e.backtrace }
  end

  def self.databases
    res = primary_db['SELECT datname FROM pg_database']

    data = []

    res.each do |r|
      data.append(r[:datname])
    end

    { ok: true, data: data }
  rescue StandardError => e
    { ok: false, details: e.message }
  end

  def self.drop_database(db_name)
    query = "DROP DATABASE #{PRIMARY_DB.literal(db_name).gsub!(/^'|'?$/, '')}"

    primary_db.execute(query)

    { ok: true }
  rescue StandardError => e
    { ok: false, details: e.message }
  end

  def self.rename_database(old_name, new_name)
    res = primary_db['SELECT datname FROM pg_database']

    db_exists = res.any? do |r|
      r[:datname] == old_name
    end

    puts db_exists
    return { ok: false, details: 'database not found' } unless db_exists

    query = "ALTER DATABASE #{PRIMARY_DB.literal(old_name).gsub!(
      /^'|'?$/,
      ''
    )} RENAME TO #{PRIMARY_DB.literal(new_name).gsub!(
      /^'|'?$/, ''
    )}"

    primary_db.execute(query)

    { ok: true }
  rescue StandardError => e
    { ok: false, details: e.message }
  end

  def self.create_table(db, name, columns)
    db_connection = Sequel.postgres db, user: ENV['DB_USER'], password: ENV['DB_PASS'], host: ENV['DB_HOST']

    types_error = false

    db_connection.create_table(name.strip.downcase.gsub(/\s+/, '_').to_sym) do
      pkey_cols = []

      columns.each do |col|
        symbolic_name = col['name'].strip.downcase.to_sym

        if col.key?('primary_key') && col['primary_key'] == true
          pkey_cols.append(symbolic_name)
          next
        end

        unless col.key?('type') && !col['type'].empty?
          types_error = true
          break
        end

        column symbolic_name, col['type']
      end

      primary_key(*pkey_cols)
    end

    raise StandardError('malformed type expression') if types_error

    { ok: true }
  rescue StandardError => e
    puts e.backtrace
    { ok: false, details: e.message }
  end

  def self.drop_table(db, name)
    db_connection = Sequel.postgres db, user: ENV['DB_USER'], password: ENV['DB_PASS'], host: ENV['DB_HOST']
    db_connection.drop_table(name.strip.downcase.gsub(/\s+/, '_').to_sym)
    { ok: true }
  rescue StandardError => e
    { ok: false, details: e.message }
  end

  def self.get_table_description(db, name)
    query = 'select column_name, data_type, is_nullable from INFORMATION_SCHEMA.COLUMNS where table_name = ?'

    db_connection = Sequel.postgres db, user: ENV['DB_USER'], password: ENV['DB_PASS'], host: ENV['DB_HOST']

    desc = db_connection[query, name.strip.downcase.gsub(/\s+/, '_')]

    items = []

    desc.each do |rec|
      puts rec
      items.append(rec)
    end

    puts items

    { ok: true, info: items }
  rescue StandardError => e
    puts e.backtrace
    { ok: false, details: e.message }
  end

  ## In alter_table we can specify only one operation at a time, but for each operation we can specify multiple columns
  def self.alter_table(db, name, column_details, operation)
    db_connection = Sequel.postgres db, user: ENV['DB_USER'], password: ENV['DB_PASS'], host: ENV['DB_HOST']

    symbolic_table_name = name.strip.downcase.gsub(/\s+/, '_').to_sym

    case operation.upcase
    when 'ADD'
      db_connection.alter_table(symbolic_table_name) do
        column_details.each do |col|
          symbolic_name = col['name'].strip.downcase.to_sym
          add_column symbolic_name, col['type']
        end
      end
    when 'DROP'

      db_connection.alter_table(symbolic_table_name) do
        column_details.each do |col|
          symbolic_name = col.strip.downcase.to_sym
          drop_column symbolic_name
        end
      end

    when 'RENAME'
      db_connection.alter_table(symbolic_table_name) do
        column_details.each do |col|
          oldsymbolic_name = col['old'].strip.downcase.to_sym
          newsymbolic_name = col['new'].strip.downcase.to_sym
          rename_column oldsymbolic_name, newsymbolic_name
        end
      end
    when 'PKEY'
      db_connection.alter_table(symbolic_table_name) do
        pkeys = []
        column_details.each do |col|
          symbolic_name = col.strip.downcase.to_sym
          pkeys.append(symbolic_name)
        end

        add_primary_key [*pkeys]
      end
    else
      raise StandardError 'unknown operation'
    end

    { ok: true }
  rescue StandardError => e
    { ok: false, details: e.message }
  end

  ## For now only positive-AND is supported in parametric way (i.e. no NOT, OR operators)
  ## The rest is supported by providing literal condition strings like "NAME = 'test' OR 'NAME' LIKE '%Y' "
  def self.select(db, table, columns, where_conditions, literal_expr)
    db_connection = Sequel.postgres db, user: ENV['DB_USER'], password: ENV['DB_PASS'], host: ENV['DB_HOST']

    symbolic_table_name = table.strip.downcase.gsub(/\s+/, '_').to_sym

    columns = columns.map(&:to_sym)

    dataset = nil
    if !literal_expr.nil?
      dataset = db_connection[symbolic_table_name].select(*columns).where(Sequel.lit(literal_expr))
    elsif where_conditions.nil?
      dataset = db_connection[symbolic_table_name].select(*columns)
    else
      where_conditions = where_conditions.transform_keys(&:to_sym)
      dataset = db_connection[symbolic_table_name].select(*columns).where(where_conditions)
    end

    { ok: true, data: dataset.all }
  rescue StandardError => e
    { ok: false, details: e.message }
  end

  def self.insert_record(db, table, inputs)
    db_connection = Sequel.postgres db, user: ENV['DB_USER'], password: ENV['DB_PASS'], host: ENV['DB_HOST']

    symbolic_table_name = table.strip.downcase.gsub(/\s+/, '_').to_sym

    inserter = db_connection[symbolic_table_name]
    inputs = inputs.transform_keys(&:to_sym)

    inserter.insert(**inputs)

    { ok: true }
  rescue StandardError => e
    { ok: false, details: e.message }
  end

  def self.delete_record(db, table, id)
    db_connection = Sequel.postgres db, user: ENV['DB_USER'], password: ENV['DB_PASS'], host: ENV['DB_HOST']

    symbolic_table_name = table.strip.downcase.gsub(/\s+/, '_').to_sym

    db_connection[symbolic_table_name].where(id: id).delete

    { ok: true }
  rescue StandardError => e
    { ok: false, details: e.message }
  end
end
