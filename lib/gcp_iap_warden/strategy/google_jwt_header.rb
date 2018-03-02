# frozen_string_literal: true

require "jwt"

module GcpIapWarden::Strategy
  class GoogleJWTHeader < Base
    self.strategy_name = :gcp_iap_google_jwt_header

    JWT_ALG = "ES256"
    JWT_ISS = "https://cloud.google.com/iap"
    JWT_HEADER = "HTTP_X_GOOG_IAP_JWT_ASSERTION"

    @key_store = GcpIapWarden::KeyStore.new

    class << self
      attr_accessor :jwt_options, :key_store

      def config(project:, backend:)
        raise "Invalid config for project" if project.nil?
        raise "Invalid config for backend" if backend.nil?

        @jwt_options = {
          algorithm: JWT_ALG,
          verify_iss: true,
          verify_iat: true,
          verify_aud: true,
          iss: JWT_ISS,
          aud:  "/projects/#{project}/global/backendServices/#{backend}",
        }
      end

      def config_reset!
        @jwt_options = nil
      end
    end

    private

    def gcp_iap_headers?
      env.key?(JWT_HEADER)
    end

    def decode_and_verify_jwt
      options = self.class.jwt_options
      raise("#{self.class} is not configured") if options.nil?
      key = nil
      token = env[JWT_HEADER]
      payload = ::JWT.decode(token, key, true, options) do |header|
        OpenSSL::PKey::EC.new(self.class.key_store.fetch(header["kid"]))
      end
      payload.first # take first part which has user info
    end

    def decode_payload
      payload = decode_and_verify_jwt
      raise "Invalid jwt payload" if payload.nil?
      {
        google_email: payload["email"],
        google_user_id: GcpIapWarden::Utils.parse_google_value(payload["sub"]),
      }
    end
  end
end

::Warden::Strategies.add(
  GcpIapWarden::Strategy::GoogleJWTHeader.strategy_name,
  GcpIapWarden::Strategy::GoogleJWTHeader
)
