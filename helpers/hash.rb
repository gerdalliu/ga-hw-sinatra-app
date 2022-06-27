# frozen_string_literal: true

require 'bcrypt'

class HashUtil
  def self.hash(password)
    BCrypt::Password.create(password)
  end

  def self.check(hash, plain)
    hash_handle = BCrypt::Password.new(hash)

    # ! If we do `plain == hashHandle` it returns false, when `hashHandle == plain` returns true.
    # ! That's because of the operator overloading
    hash_handle == plain
  end
end
