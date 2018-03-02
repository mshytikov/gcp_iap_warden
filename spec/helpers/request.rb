# frozen_string_literal: true

module GcpIapWarden::Spec::Helpers
  module Request
    def setup_rack(strategy)
      app = success_app
      default_failure_app = failure_app

      ::Rack::Builder.new do
        use ::Warden::Manager do |manager|
          manager.default_strategies strategy
          manager.failure_app = default_failure_app
        end
        run app
      end
    end

    def failure_app
      ->(_e) { [401, { "Content-Type" => "text/plain" }, ["Fail"]] }
    end

    def success_app
      lambda { |env|
        env["warden"].authenticate!
        [200, { "Content-Type" => "text/plain" }, ["OK"]]
      }
    end
  end
end
