# frozen_string_literal: true

module GcpIapWarden
  module Strategy
    require_relative "strategy/base"
    require_relative "strategy/google_header"
    require_relative "strategy/google_jwt_header"
  end
end
