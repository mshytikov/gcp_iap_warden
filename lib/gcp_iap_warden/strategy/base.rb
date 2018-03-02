# frozen_string_literal: true

module GcpIapWarden::Strategy
  class Base < ::Warden::Strategies::Base
    class << self
      attr_accessor :strategy_name
    end

    def store?
      false
    end

    def valid?
      gcp_iap_headers?
    end

    def authenticate!
      success!(validate_payload(decode_payload))
    rescue StandardError => e
      errors.add(self.class.strategy_name, e.message)
      self.fail # rubocop:disable Style/RedundantSelf
    end

    private

    def validate_payload(payload)
      raise "Invalid google email" if payload[:google_email].nil?
      raise "Invalid google user id" if payload[:google_user_id].nil?
      payload
    end
  end
end
