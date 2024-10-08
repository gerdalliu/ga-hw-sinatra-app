# frozen_string_literal: true

require 'bcrypt'

class HashUtil
  def self.hash(password)
    BCrypt::Password.create(password)
  end

  def self.check(hash, plain)
    hash_handle = BCrypt::Password.new(hash)

    # '==' is an overloaded operator
    hash_handle == plain
  end
end
