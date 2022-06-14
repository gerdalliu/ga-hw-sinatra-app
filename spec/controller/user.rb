require_relative "../../helpers/hash"

class UserController < Sinatra::Application
    
    def self.getOne(id)
        "user_#{id}"
    end

    def self.createOne(userData)
        
        #! validations of fields can take place here if needed

        userExists = User.where(email: userData['email']).any? {|u| true}

        if userExists
            return {:ok => false, :detail => "User already exists"}
        end

        user = User.create do |u|
            u.username = userData['username']
            u.firstname = userData['firstname']
            u.lastname = userData['lastname']
            u.password = HashUtil.hash(userData['password'])
            u.email =  userData['email']
            u.isadmin = false
            u.city =  userData['city']
            u.age =  userData['age']
          end

        # user.delete('password')
        return {:ok => true, :user => user.to_hash}
    end

    def self.deleteOne()
    end

    def self.updateOne()
    end

    def self.auth(email, password)
        user = User.where(email: email).find {|u| HashUtil.check(u.password, password)}

        if user != nil
            summary = {:ok => true}
            if user.isadmin
                summary[:permissions] = "ADMIN"
            else
                summary[:permissions] = "USER"
            end

            return summary
        end

        return {:ok => false}

    end
end

