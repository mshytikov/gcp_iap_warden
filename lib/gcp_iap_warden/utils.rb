# frozen_string_literal: true

module GcpIapWarden::Utils
  GOOGLE_VALUE_PREFIX = "accounts.google.com:"
  # returns value of google headers prefixed with `accounts.google.com:`
  # example:
  #   parse_google_value("accounts.google.com:example@gmail.com")
  #   => example@gmail.com
  #
  def self.parse_google_value(str)
    str.sub(GOOGLE_VALUE_PREFIX, "") if str&.start_with?(GOOGLE_VALUE_PREFIX)
  end
end
