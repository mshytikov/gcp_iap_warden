# frozen_string_literal: true

require "bundler/setup"
require "rspec-parameterized"
require "rspec/its"
require "rack/test"
require "timecop"
require "vcr"
require "webmock/rspec"
require "gcp_iap_warden"

module GcpIapWarden
  module Spec
    require_relative "helpers/request"
    require_relative "helpers/fixture"
  end
end

VCR.configure do |config|
  config.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  config.hook_into :webmock
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
