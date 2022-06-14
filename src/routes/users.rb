# frozen_string_literal: true

require_relative '../controller/user'
require_relative '../../helpers/token'

class UserRoutes < Sinatra::Base
  register Sinatra::Namespace

  use AuthMiddleware

  before do
    content_type 'application/json'
  end

  configure :development do
    enable :logging
  end

  #=> Login
  get('/login') do
    # payload = params
    # payload = JSON.parse(request.body.read) unless params["path"]

    summary = UserController.auth(params['email'], params['password'])

    if summary[:ok]
      token_payload = { permissions: summary[:permissions] } # ! ADMIN or USER

      { "token": JWTUtil.create_jwt(token_payload) }.to_json
    else
      halt 409, 'Login failed!'
    end
  end

  post('/register') do
    payload = params
    payload = JSON.parse(request.body.read) unless params[:path]

    logger.info "Creating user with #{payload[:meta]}"

    summary = UserController.create_one(payload)

    if summary[:ok]

      token_payload = if summary[:user][:isadmin]
                        { permissions: 'ADMIN' }
                      else
                        { permissions: 'USER' }
                      end

      token = JWTUtil.create_jwt(token_payload)

      { user: summary[:user], msg: 'User created.', token: token }.to_json
    else
      { msg: 'Could not create user.', details: summary[:detail] }.to_json
    end
  end

  delete('/') do
    if request.env['A9_PERMISSIONS'] != 'USER'
      return {
        msg: 'Could not delete account.',
        detail: 'You need to log in first!'
      }.to_json
    end

    summary = UserController.auth(params['email'], params['password'])

    return { msg: 'Could not delete account.', detail: 'User not found or wrong password' }.to_json unless summary[:ok]

    summary = UserController.delete_one(params['email'])

    if summary[:ok]
      { msg: 'Account deleted.' }.to_json
    else
      { msg: 'Could not delete account.' }.to_json
    end
  end

  namespace '/admin' do
    get('/') do
      summary = UserController.get_one(params['id'])

      summary[:user] if summary[:ok]
    end

    post('/create') do
      payload = params
      payload = JSON.parse(request.body.read) unless params[:path]

      summary = UserController.create_one(payload)

      if summary[:ok]
        { user: summary[:user], msg: 'User created.' }.to_json
      else
        { msg: 'Could not create user.' }.to_json
      end
    end

    put('/update') do
      payload = params
      payload = JSON.parse(request.body.read) unless params[:path]

      summary = UserController.update_one(payload)

      if summary[:ok]
        { user: summary[:user], msg: 'User updated.' }.to_json
      else
        { msg: 'Could not create user.' }.to_json
      end
    end

    delete('/:id') do
      ok = UserController.delete_one(params['id'])

      if ok
        { msg: 'User deleted.' }.to_json
      else
        { msg: 'Could not delete user.' }.to_json
      end
    end
    # ~~   namespace '/admin', :provides => ['json'] do
  end
end
