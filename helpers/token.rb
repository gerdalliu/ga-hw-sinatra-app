# frozen_string_literal: true

require 'jwt'
require 'openssl'

class JWTUtil
  def self.create_jwt(payload)
    rsa_key = OpenSSL::PKey::RSA.new(File.read('util/sec/privkey'))
    exp = Time.now.to_i + 4 * 3600
    payload['exp'] = exp

    JWT.encode payload, rsa_key, 'RS256'
  end
end
