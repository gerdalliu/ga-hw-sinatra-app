root = ::File.dirname(__FILE__)
require ::File.join( root, 'app' )

map '/' do 
    homeApp = HomeRoutes.new
    # homeApp.use AuthMiddleware
    run homeApp
end

map '/users' do 
    usersApp = UserRoutes.new
    # usersApp.use AuthMiddleware
    run usersApp
end

