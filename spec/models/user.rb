# frozen_string_literal: true

# ! specifying the table manually because it is plural
class User < Sequel::Model(:users)
end
