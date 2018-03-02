# frozen_string_literal: true

module GcpIapWarden::Spec::Helpers
  module Fixture
    ROOT = File.expand_path("../fixtures", __dir__)
    def self.read(file_name)
      File.read(path(file_name))
    end

    def self.path(file_name)
      File.join(ROOT, file_name)
    end
  end
end
