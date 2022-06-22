# frozen_string_literal: true

require_relative '../../helpers/hash'

class UserController < Sinatra::Application

  def self.USER_DB
    unless defined? @UDB
      @UDB = Sequel.postgres ENV['USER_DB_NAME'], user: ENV['DB_USER'], password: ENV['DB_PASS'], host: ENV['DB_HOST']
    end

    return @UDB
  end

  def get_one(id)
    user = self.USER_DB[:users].where(id: id).delete
    { ok: true, user: user.to_hash }
  end

  def self.create_one(user_data)
    # ! validations of fields can take place here if needed

    user_exists = self.USER_DB[:users].where(email: user_data['email']).any? { |_u| true }

    return { ok: false, detail: 'User already exists' } if user_exists

    user = self.USER_DB[:users].insert({
      :username => user_data['username'],
      :firstname => user_data['firstname'],
      :lastname => user_data['lastname'],
      :password => HashUtil.hash(user_data['password']),
      :email =>  user_data['email'],
      :isadmin => false,
      :city =>  user_data['city'],
      :age => user_data['age']
      })
     

    # user.delete('password')
    { ok: true }
  end

  def self.delete_one(email)
    self.USER_DB[:users].where(email: email).delete
    { ok: true }
  end

  def self.update_one(user_data)
    # ! validations of fields can take place here if needed
    user_exists = self.USER_DB[:users].where(email: user_data['email']).any? { |_u| true }

    return { ok: false, detail: 'User not found.' } unless user_exists

    user = self.USER_DB[:users].where(Sequel[:id]).update({
      :username => user_data['username'],
      :firstname => user_data['firstname'],
      :lastname => user_data['lastname'],
      :password => HashUtil.hash(user_data['password']),
      :email =>  user_data['email'],
      :isadmin => false,
      :city =>  user_data['city'],
      :age => user_data['age']
    })
    

    # user.delete('password')
    { ok: true, user: user.to_hash }
  end

  def self.auth(email, password)

    user = self.USER_DB[:users].where(email: email).find { |u| HashUtil.check(u[:password], password) }

    unless user.nil?

      puts user.to_hash

      summary = { ok: true }
      summary[:permissions] = if user[:isadmin]
                                'ADMIN'
                              else
                                'USER'
                              end

      return summary
    end

    { ok: false }
  end
end
