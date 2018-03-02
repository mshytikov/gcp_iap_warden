# frozen_string_literal: true

RSpec.describe GcpIapWarden::Strategy::GoogleJWTHeader do
  include Rack::Test::Methods
  include GcpIapWarden::Spec::Helpers::Request

  Fixture = GcpIapWarden::Spec::Helpers::Fixture

  let(:header_value) { Fixture.read("google_jwt_header_value.txt") }
  let(:project) { "593755045751" }
  let(:backend) { "1189510079829359176" }
  let(:request_headers) do
    {
      "X-Goog-IAP-JWT-Assertion" =>
      Fixture.read("google_jwt_header_value.txt"),
    }
  end
  let(:app) { setup_rack(:gcp_iap_google_jwt_header) }

  def make_request(request_headers, time: "2018-01-24T15:08:49")
    VCR.use_cassette("google_iap_keys") do
      Timecop.freeze(time) do
        request_headers.each { |k, v| header(k, v) }
        get "/"
      end
    end
  end

  def init_strategy(project, backend)
    GcpIapWarden::Strategy::GoogleJWTHeader.config(
      project: project,
      backend: backend
    )
  end

  after do
    GcpIapWarden::Strategy::GoogleJWTHeader.config_reset!
  end

  shared_examples_for "unauthorized" do
    describe "response" do
      subject { last_response }
      it { is_expected.to be_unauthorized }
    end

    describe "warden env" do
      subject { last_request.env["warden"] }
      its("errors.full_messages") { is_expected.to eq([expected_error]) }
      its(:user) { is_expected.to be_nil }
    end
  end

  describe "successfull cases" do
    before { init_strategy(project, backend) }
    before { make_request(request_headers) }

    describe "response" do
      subject { last_response }
      it { is_expected.to be_ok }
    end

    describe "warden env" do
      subject { last_request.env["warden"] }
      let(:expected_user) do
        {
          google_email: "reporting@bloomon.nl",
          google_user_id: "110724539886910602265",
        }
      end
      its(:errors) { is_expected.to be_empty }
      its(:user) { is_expected.to eq(expected_user) }
    end
  end

  describe "invalid configuration" do
    context "when strategy is not configured" do
      before { make_request(request_headers) }

      it_behaves_like "unauthorized" do
        let(:expected_error) do
          "GcpIapWarden::Strategy::GoogleJWTHeader is not configured"
        end
      end
    end

    context "when strategy is wrongly configured" do
      where(:project, :backend, :expected_msg) do
        [
          [nil, "234234234", "Invalid config for project"],
          ["234234234", nil, "Invalid config for backend"],
        ]
      end

      subject { init_strategy(project, backend) }

      with_them do
        it { expect { subject }.to raise_error(RuntimeError, expected_msg) }
      end
    end
  end

  describe "unsuccessfull cases" do
    before { init_strategy(project, backend) }
    before { make_request(request_headers) }

    context "when jwt header is missing " do
      let(:request_headers) { {} }
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

    context "when jwt alg is not mathing" do
      before do
        stub_const(
          "GcpIapWarden::Strategy::GoogleJWTHeader::JWT_ALG",
          "RS256"
        )
      end

      before { init_strategy(project, backend) }
      before { make_request(request_headers) }

      it_behaves_like "unauthorized" do
        let(:expected_error) { "Expected a different algorithm" }
      end
    end

    context "when jwt iss invalid" do
      before do
        stub_const(
          "GcpIapWarden::Strategy::GoogleJWTHeader::JWT_ISS",
          "https://cloud.google.com/iap-fake"
        )
      end

      before { init_strategy(project, backend) }
      before { make_request(request_headers) }

      it_behaves_like "unauthorized" do
        let(:expected_error) do
          "Invalid issuer. " \
          "Expected https://cloud.google.com/iap-fake, " \
          "received https://cloud.google.com/iap"
        end
      end
    end

    context "when jwt aud is invalid" do
      let(:project) { "234234234" }

      before { init_strategy(project, backend) }
      before { make_request(request_headers) }

      it_behaves_like "unauthorized" do
        let(:expected_error) do
          "Invalid audience. " \
          "Expected" \
          " /projects/234234234/global/backendServices/1189510079829359176, " \
          "received" \
          " /projects/593755045751/global/backendServices/1189510079829359176"
        end
      end
    end

    context "when jwt iat is invalid" do
      before { init_strategy(project, backend) }
      before { make_request(request_headers, time: "2018-01-01T01:01:01") }

      it_behaves_like "unauthorized" do
        let(:expected_error) { "Invalid iat" }
      end
    end

    context "when jwt is expired" do
      before { init_strategy(project, backend) }
      before { make_request(request_headers, time: Time.now.iso8601) }

      it_behaves_like "unauthorized" do
        let(:expected_error) { "Signature has expired" }
      end
    end
  end
end
