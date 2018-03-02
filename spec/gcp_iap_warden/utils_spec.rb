# frozen_string_literal: true

RSpec.describe GcpIapWarden::Utils do
  describe ".parse_google_value" do
    subject { GcpIapWarden::Utils.parse_google_value(value) }

    where(:value, :expected_value) do
      [
        [nil, nil],
        ["example@gmail.com", nil],
        ["12341234123412353", nil],
        ["accounts.google.com:example@gmail.com", "example@gmail.com"],
        ["accounts.google.com:12341234123412353", "12341234123412353"],
      ]
    end
    with_them do
      it { is_expected.to eq(expected_value) }
    end
  end
end
