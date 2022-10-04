# frozen_string_literal: true

RSpec.describe OmniEvent::Strategies::API do
  let(:response_body) { { "events" => [{ "name" => "My event" }] } }
  let(:request_path) { "event" }

  before do
    allow_any_instance_of(described_class).to receive(:request_url).and_return("https://api.com")
    allow_any_instance_of(described_class).to receive(:request_headers).and_return(
      { "Authorization" => "Bearer 12345" }
    )
  end

  describe "perform_request" do
    it "performs api requests" do
      stub_request(:get, "https://api.com/#{request_path}")
        .with(headers: { "Authorization" => "Bearer 12345" })
        .to_return(body: response_body.to_json, headers: { "Content-Type" => "application/json" })

      expect(described_class.new.perform_request(path: request_path)).to eq(response_body)
    end

    it "handles redirects" do
      stub_request(:get, "https://api.com/#{request_path}")
        .with(headers: { "Authorization" => "Bearer 12345" })
        .to_return(status: 302, headers: { "Location" => "https://api.com/events-new" })
        .to_return(body: response_body.to_json, headers: { "Content-Type" => "application/json" })

      expect(described_class.new.perform_request(path: request_path)).to eq(response_body)
    end
  end
end
