# frozen_string_literal: true

root = ::File.dirname(__FILE__)
require ::File.join(root, 'app')

map '/' do
  home_app = HomeRoutes.new
  run home_app
end

map '/users' do
  users_app = UserRoutes.new
  run users_app
end

map '/db' do
  db_app = DatabaseRoutes.new
  run db_app
end
