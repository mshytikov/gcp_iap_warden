# frozen_string_literal: true

require "open-uri"

module GcpIapWarden
  class KeyStore
    GOOGLE_PUBLIC_KEY_URL = "https://www.gstatic.com/iap/verify/public_key"

    def initialize
      @keys = {}
    end

    def fetch(key_id)
      return if key_id.nil?
      key = keys[key_id]
      return key if key

      update_keys!(key_id)
      keys.fetch(key_id)
    end

    private

    attr_accessor :keys

    def update_keys!(key_id)
      new_keys = load_keys
      raise "Can't find key with id: #{key_id}" unless new_keys.key?(key_id)
      self.keys = new_keys
    end

    def load_keys
      ::JSON.parse(open(GOOGLE_PUBLIC_KEY_URL).read)
    end
  end
end
