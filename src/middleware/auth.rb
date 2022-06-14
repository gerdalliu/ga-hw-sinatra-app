# frozen_string_literal: true

require 'jwt'
require 'openssl'
require 'sinatra/namespace'
require 'sinatra/multi_route'
require 'json'

class AuthMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    @req = Rack::Request.new(env)

    if should_authenticate?
      auth_token = env.fetch('HTTP_AUTHORIZATION')[7..]

      fkey = File.read('./util/sec/pubkey')
      pubkey = OpenSSL::PKey::RSA.new(fkey)

      decoded_token = JWT.decode auth_token, pubkey, false, { algorithm: 'RS256' }

      if admin_duties? && decoded_token[0]['permissions'] != 'ADMIN'
        Rack::Response.new(
          'INSUFFICIENT PRIVILEGES',
          405,
          {}
        ).finish
      end

      @req.set_header('A9_PERMISSIONS', decoded_token[0]['permissions'])
    end

    status, headers, response = @app.call(env)
    headers['Content-Type'] = 'application/json'

    [status, headers, response]
  rescue JWT::ExpiredSignature => e
    puts "EXPIRED TOKEN: #{e.message}"

    Rack::Response.new('EXPIRED TOKEN', 402, {}).finish
  rescue StandardError => e
    puts "ERR: #{e}"

    Rack::Response.new('SOMETHING WENT WRONG', 501, {}).finish
  end

  def admin_duties?
    @req.path.match?(%r{.*/*admin/*.*}) || @req.path.match?(%r{.*/*db/*.*})
  end

  def should_authenticate?
    admin_duties? || @req.request_method == 'DELETE'
  end
end
