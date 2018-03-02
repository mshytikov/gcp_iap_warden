# frozen_string_literal: true

RSpec.describe GcpIapWarden::Strategy::GoogleHeader do
  include Rack::Test::Methods
  include GcpIapWarden::Spec::Helpers::Request

  let(:app) { setup_rack(:gcp_iap_google_header) }

  def make_request(request_headers)
    request_headers.each { |k, v| header(k, v) }
    get "/"
  end

  describe "successfull cases" do
    let(:request_headers) do
      {
        "X-Goog-Authenticated-User-Email" =>
        "accounts.google.com:example@gmail.com",

        "X-Goog-Authenticated-User-ID" =>
        "accounts.google.com:3415345123513513",
      }
    end

    before { make_request(request_headers) }

    describe "response" do
      subject { last_response }
      it { is_expected.to be_ok }
    end

    describe "warden env" do
      subject { last_request.env["warden"] }
      let(:expected_user) do
        {
          google_email: "example@gmail.com",
          google_user_id: "3415345123513513",
        }
      end
      its(:errors) { is_expected.to be_empty }
      its(:user) { is_expected.to eq(expected_user) }
    end
  end

  describe "unsuccessfull cases" do
    before { make_request(request_headers) }

    context "when some headers are missing " do
      where(:request_headers) do
        [
          {},
          {
            "X-Goog-Authenticated-User-Email" =>
            "accounts.google.com:example@gmail.com",
          },
          {
            "X-Goog-Authenticated-User-ID" =>
            "accounts.google.com:3415345123513513",
          },
        ]
      end

      with_them do
        describe "response" do
          subject { last_response }
          it { is_expected.to be_unauthorized }
        end

        describe "warden env" do
          subject { last_request.env["warden"] }
          its(:errors) { is_expected.to be_empty }
          its(:user) { is_expected.to be_nil }
        end
      end
    end

    context "when headers have invalid values" do
      where(:request_headers, :expected_errors) do
        [
          [
            {
              "X-Goog-Authenticated-User-Email" => "example@gmail.com",
              "X-Goog-Authenticated-User-ID" => "accounts.google.com:341534",
            },
            ["Invalid google email"],
          ],
          [
            {
              "X-Goog-Authenticated-User-Email" =>
              "accounts.google.com:example@gmail.com",
              "X-Goog-Authenticated-User-ID" => "341534",
            },
            ["Invalid google user id"],
          ],
        ]
      end

      with_them do
        describe "response" do
          subject { last_response }
          it { is_expected.to be_unauthorized }
        end

        describe "warden env" do
          subject { last_request.env["warden"] }
          its("errors.full_messages") { is_expected.to eq(expected_errors) }
          its(:user) { is_expected.to be_nil }
        end
      end
    end
  end
end
