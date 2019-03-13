# GCP IAP Warden

Google Cloud [Cloud Identity-Aware Proxy](https://cloud.google.com/iap/)
 strategies for [Warden](https://github.com/hassox/warden)

## Usage

Below is just an example for ussage with rails.
But you can easily reuse the code for you rack based app.

Read more about Warden [here](https://github.com/hassox/warden/wiki)

You may have use different strategies:
`gcp_iap_google_jwt_header` or `gcp_iap_google_header`

Recommended is `gcp_iap_google_jwt_header` read more [here](https://cloud.google.com/iap/docs/signed-headers-howto)

Initialize the warden with something like

```
# ./config/initializers/warden.rb

require "gcp_iap_warden"

GcpIapWarden::Strategy::GoogleJWTHeader.config(
  project: ENV.fetch("GCP_PROJECT_ID"),
  backend: ENV.fetch("GCP_BACKEND_ID")
)

Rails.application.config.middleware.insert_after(
  ActionDispatch::Session::CookieStore, Warden::Manager
) do |manager|
  manager.default_strategies :gcp_iap_google_jwt_header
  manager.failure_app = UnauthorizedController
end
```

Or for AppEngine like

```
# ./config/initializers/warden.rb

require "gcp_iap_warden"

GcpIapWarden::Strategy::GoogleJWTHeader.config(
  project: ENV.fetch("GCP_PROJECT_ID"),
  backend: ENV.fetch("APP_ENGINE_PROJECT_ID")
  platform: :app_engine
)

Rails.application.config.middleware.insert_after(
  ActionDispatch::Session::CookieStore, Warden::Manager
) do |manager|
  manager.default_strategies :gcp_iap_google_jwt_header
  manager.failure_app = UnauthorizedController
end
```

Your `UnauthorizedController` may look like

```
# app/controllers/unauthorized_controller.rb

class UnauthorizedController < ActionController::Metal
  def self.call(env)
    env["warden"].errors.each do |message|
      Rails.logger.warn("[unauthorized] reason: #{message}")
    end
    @respond ||= action(:respond)
    @respond.call(env)
  end

  def respond
    self.response_body = "Unauthorized Action"
    self.status = :unauthorized
  end
end
```

## Development

Setup and run tests

```
docker-compose run --rm app ./bin/setup
```
