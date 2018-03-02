# frozen_string_literal: true

module GcpIapWarden::Strategy
  class GoogleHeader < Base
    self.strategy_name = :gcp_iap_google_header

    USER_EMAIL_HEADER = "HTTP_X_GOOG_AUTHENTICATED_USER_EMAIL"
    USER_ID_HEADER = "HTTP_X_GOOG_AUTHENTICATED_USER_ID"

    private

    def gcp_iap_headers?
      env.key?(USER_EMAIL_HEADER) && env.key?(USER_ID_HEADER)
    end

    def decode_payload
      email_value = env.fetch(USER_EMAIL_HEADER)
      user_id_value = env.fetch(USER_ID_HEADER)
      {
        google_email: GcpIapWarden::Utils.parse_google_value(email_value),
        google_user_id:  GcpIapWarden::Utils.parse_google_value(user_id_value),
      }
    end
  end
end

::Warden::Strategies.add(
  GcpIapWarden::Strategy::GoogleHeader.strategy_name,
  GcpIapWarden::Strategy::GoogleHeader
)
