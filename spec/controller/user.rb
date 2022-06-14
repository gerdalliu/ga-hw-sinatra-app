class UserController < Sinatra::Application
    
    def self.getOne(id)
        "user_#{id}"
    end

    def self.getMultiple()
    end

    def self.createOne()
    end

    def self.createMultiple()
    end

    def self.deleteOne()
    end

    def self.deleteMany()
    end

    def self.updateOne()
    end

    def self.updateMany()
    end
end