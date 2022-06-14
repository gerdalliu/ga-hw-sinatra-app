
class HomeRoutes < Sinatra::Base
    register Sinatra::Namespace

    use AuthMiddleware
    
    before do
        content_type 'application/json'
    end

    configure :development do
        enable :logging
    end

    get('/') do
        "Home Page"
    end

    configure :development do
        enable :logging
        set :default_content_type, :json
    end

    get('/health') do
        {msg:"Doing a Corona Test.. Everything seems fine"}.to_json
    end

end