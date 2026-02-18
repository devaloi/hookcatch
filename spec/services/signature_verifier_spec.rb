require "rails_helper"

RSpec.describe SignatureVerifier do
  describe ".verify!" do
    context "with GitHub provider" do
      let(:body) { github_payload.to_json }
      let(:headers) { { "HTTP_X_HUB_SIGNATURE_256" => sign_github(body) } }

      it "accepts valid signature" do
        expect {
          described_class.verify!(provider: "github", raw_body: body, headers: headers)
        }.not_to raise_error
      end

      it "rejects invalid signature" do
        headers["HTTP_X_HUB_SIGNATURE_256"] = "sha256=invalid"
        expect {
          described_class.verify!(provider: "github", raw_body: body, headers: headers)
        }.to raise_error(SignatureVerifier::InvalidSignature, "Invalid signature")
      end

      it "rejects missing signature" do
        expect {
          described_class.verify!(provider: "github", raw_body: body, headers: {})
        }.to raise_error(SignatureVerifier::InvalidSignature, "Missing signature header")
      end
    end

    context "with Stripe provider" do
      let(:body) { stripe_payment_payload.to_json }
      let(:timestamp) { Time.now.to_i }
      let(:headers) { { "HTTP_STRIPE_SIGNATURE" => sign_stripe(body, timestamp: timestamp) } }

      it "accepts valid signature" do
        expect {
          described_class.verify!(provider: "stripe", raw_body: body, headers: headers)
        }.not_to raise_error
      end

      it "rejects invalid signature" do
        headers["HTTP_STRIPE_SIGNATURE"] = "t=#{timestamp},v1=invalid"
        expect {
          described_class.verify!(provider: "stripe", raw_body: body, headers: headers)
        }.to raise_error(SignatureVerifier::InvalidSignature, "Invalid signature")
      end

      it "rejects missing signature" do
        expect {
          described_class.verify!(provider: "stripe", raw_body: body, headers: {})
        }.to raise_error(SignatureVerifier::InvalidSignature, "Missing signature header")
      end

      it "rejects expired timestamp" do
        old_timestamp = Time.now.to_i - 600
        headers["HTTP_STRIPE_SIGNATURE"] = sign_stripe(body, timestamp: old_timestamp)
        expect {
          described_class.verify!(provider: "stripe", raw_body: body, headers: headers)
        }.to raise_error(SignatureVerifier::InvalidSignature, "Timestamp outside tolerance")
      end
    end

    context "with generic provider" do
      let(:body) { generic_payload.to_json }
      let(:headers) { { "HTTP_X_SIGNATURE_256" => sign_generic(body) } }

      it "accepts valid signature" do
        expect {
          described_class.verify!(provider: "generic", raw_body: body, headers: headers)
        }.not_to raise_error
      end

      it "rejects invalid signature" do
        headers["HTTP_X_SIGNATURE_256"] = "sha256=invalid"
        expect {
          described_class.verify!(provider: "generic", raw_body: body, headers: headers)
        }.to raise_error(SignatureVerifier::InvalidSignature, "Invalid signature")
      end

      it "rejects missing signature" do
        expect {
          described_class.verify!(provider: "generic", raw_body: body, headers: {})
        }.to raise_error(SignatureVerifier::InvalidSignature, "Missing signature header")
      end
    end

    context "with unknown provider" do
      it "raises InvalidSignature" do
        expect {
          described_class.verify!(provider: "unknown", raw_body: "{}", headers: {})
        }.to raise_error(SignatureVerifier::InvalidSignature, /Unknown provider/)
      end
    end
  end

  describe ".extract_metadata" do
    it "extracts GitHub metadata" do
      body = github_payload.to_json
      headers = {
        "HTTP_X_GITHUB_DELIVERY" => "gh-delivery-123",
        "HTTP_X_GITHUB_EVENT" => "push"
      }
      metadata = described_class.extract_metadata(provider: "github", raw_body: body, headers: headers)
      expect(metadata[:delivery_id]).to eq("gh-delivery-123")
      expect(metadata[:event_type]).to eq("push")
    end

    it "extracts Stripe metadata" do
      payload = stripe_payment_payload(id: "evt_test_456", type: "payment_intent.succeeded")
      body = payload.to_json
      metadata = described_class.extract_metadata(provider: "stripe", raw_body: body, headers: {})
      expect(metadata[:delivery_id]).to eq("evt_test_456")
      expect(metadata[:event_type]).to eq("payment_intent.succeeded")
    end

    it "extracts generic metadata" do
      body = generic_payload(event: "order.placed").to_json
      headers = { "HTTP_X_DELIVERY_ID" => "gen-789" }
      metadata = described_class.extract_metadata(provider: "generic", raw_body: body, headers: headers)
      expect(metadata[:delivery_id]).to eq("gen-789")
      expect(metadata[:event_type]).to eq("order.placed")
    end
  end
end
