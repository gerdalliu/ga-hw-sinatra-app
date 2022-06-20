# frozen_string_literal: true

require_relative '../../helpers/hash'

class UserController < Sinatra::Application
  def self.get_one(id)
    user = User.where(id: id).delete
    { ok: true, user: user.to_hash }
  end

  def self.create_one(user_data)
    # ! validations of fields can take place here if needed

    user_exists = User.where(email: user_data['email']).any? { |_u| true }

    return { ok: false, detail: 'User already exists' } if user_exists

    user = User.create do |u|
      u.username = user_data['username']
      u.firstname = user_data['firstname']
      u.lastname = user_data['lastname']
      u.password = HashUtil.hash(user_data['password'])
      u.email =  user_data['email']
      u.isadmin = false
      u.city =  user_data['city']
      u.age = user_data['age']
    end

    # user.delete('password')
    { ok: true, user: user.to_hash }
  end

  def self.delete_one(email)
    User.where(email: email).delete
    { ok: true }
  end

  def self.update_one(user_data)
    # ! validations of fields can take place here if needed
    user_exists = User.where(email: user_data['email']).any? { |_u| true }

    return { ok: false, detail: 'User not found.' } unless user_exists

    user = User.where(u.id).update do |u|
      u.username = user_data['username']
      u.firstname = user_data['firstname']
      u.lastname = user_data['lastname']
      u.password = HashUtil.hash(user_data['password'])
      u.email =  user_data['email']
      u.isadmin = user_data['is_admin']
      u.city =  user_data['city']
      u.age = user_data['age']
    end

    # user.delete('password')
    { ok: true, user: user.to_hash }
  end

  def self.auth(email, password)
    user = User.where(email: email).find { |u| HashUtil.check(u.password, password) }

    unless user.nil?

      puts user.to_hash

      summary = { ok: true }
      summary[:permissions] = if user.isadmin
                                'ADMIN'
                              else
                                'USER'
                              end

      return summary
    end

    { ok: false }
  end
end
