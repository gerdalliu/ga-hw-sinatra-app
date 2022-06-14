require 'bcrypt'

class HashUtil

    def self.hash(password)
        BCrypt::Password.create(password) #=> returns hash for storing
    end

    def self.check(hash, plain)
        hashHandle = BCrypt::Password.new(hash)

        #! Why I hate Ruby: If we do `plain == hashHandle` it returns false, when `hashHandle == plain` returns true.
        hashHandle == plain

    end

end
