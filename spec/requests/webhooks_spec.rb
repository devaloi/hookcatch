require "rails_helper"

RSpec.describe "Webhooks", type: :request do
  describe "POST /webhooks/:provider" do
    context "with valid GitHub webhook" do
      let(:body) { github_payload.to_json }

      it "returns 200 and enqueues job" do
        post "/webhooks/github", params: body, headers: {
          "CONTENT_TYPE" => "application/json",
          "X-Hub-Signature-256" => sign_github(body),
          "X-GitHub-Delivery" => "gh-123",
          "X-GitHub-Event" => "push"
        }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["status"]).to eq("accepted")
        expect(json["delivery_id"]).to eq("gh-123")
        expect(WebhookDelivery.count).to eq(1)
      end
    end

    context "with valid Stripe webhook" do
      let(:payload) { stripe_payment_payload(id: "evt_stripe_test") }
      let(:body) { payload.to_json }
      let(:timestamp) { Time.now.to_i }

      it "returns 200 and enqueues job" do
        post "/webhooks/stripe", params: body, headers: {
          "CONTENT_TYPE" => "application/json",
          "Stripe-Signature" => sign_stripe(body, timestamp: timestamp)
        }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["status"]).to eq("accepted")
      end
    end

    context "with valid generic webhook" do
      let(:body) { generic_payload.to_json }

      it "returns 200 and enqueues job" do
        post "/webhooks/generic", params: body, headers: {
          "CONTENT_TYPE" => "application/json",
          "X-Signature-256" => sign_generic(body),
          "X-Delivery-ID" => "gen-456"
        }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["status"]).to eq("accepted")
      end
    end

    context "with invalid signature" do
      it "returns 401" do
        body = github_payload.to_json
        post "/webhooks/github", params: body, headers: {
          "CONTENT_TYPE" => "application/json",
          "X-Hub-Signature-256" => "sha256=invalid",
          "X-GitHub-Delivery" => "gh-bad",
          "X-GitHub-Event" => "push"
        }

        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json["error"]).to include("Invalid signature")
      end
    end

    context "with missing signature" do
      it "returns 401" do
        body = github_payload.to_json
        post "/webhooks/github", params: body, headers: {
          "CONTENT_TYPE" => "application/json",
          "X-GitHub-Delivery" => "gh-nosig",
          "X-GitHub-Event" => "push"
        }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with duplicate delivery_id" do
      it "returns 200 with duplicate status" do
        create(:webhook_delivery, delivery_id: "gh-dup")

        body = github_payload.to_json
        post "/webhooks/github", params: body, headers: {
          "CONTENT_TYPE" => "application/json",
          "X-Hub-Signature-256" => sign_github(body),
          "X-GitHub-Delivery" => "gh-dup",
          "X-GitHub-Event" => "push"
        }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["status"]).to eq("duplicate")
      end
    end

    context "with unknown provider" do
      it "returns 404" do
        post "/webhooks/unknown", params: "{}", headers: {
          "CONTENT_TYPE" => "application/json"
        }

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "Admin endpoints" do
    describe "without JWT" do
      it "GET /webhooks/deliveries returns 401" do
        get "/webhooks/deliveries"
        expect(response).to have_http_status(:unauthorized)
      end

      it "GET /webhooks/deliveries/:id returns 401" do
        delivery = create(:webhook_delivery)
        get "/webhooks/deliveries/#{delivery.id}"
        expect(response).to have_http_status(:unauthorized)
      end

      it "POST /webhooks/deliveries/:id/replay returns 401" do
        delivery = create(:webhook_delivery)
        post "/webhooks/deliveries/#{delivery.id}/replay"
        expect(response).to have_http_status(:unauthorized)
      end

      it "GET /webhooks/dead_letters returns 401" do
        get "/webhooks/dead_letters"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    describe "with valid JWT" do
      describe "GET /webhooks/deliveries" do
        it "returns paginated deliveries" do
          create_list(:webhook_delivery, 3)

          get "/webhooks/deliveries", headers: auth_headers
          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json["deliveries"].length).to eq(3)
          expect(json["meta"]).to be_present
        end

        it "filters by provider" do
          create(:webhook_delivery, provider: "github")
          create(:webhook_delivery, :stripe)

          get "/webhooks/deliveries", params: { provider: "github" }, headers: auth_headers
          json = JSON.parse(response.body)
          expect(json["deliveries"].length).to eq(1)
          expect(json["deliveries"][0]["provider"]).to eq("github")
        end

        it "filters by status" do
          create(:webhook_delivery, status: :completed)
          create(:webhook_delivery, status: :failed)

          get "/webhooks/deliveries", params: { status: "failed" }, headers: auth_headers
          json = JSON.parse(response.body)
          expect(json["deliveries"].length).to eq(1)
          expect(json["deliveries"][0]["status"]).to eq("failed")
        end
      end

      describe "GET /webhooks/deliveries/:id" do
        it "returns delivery details with payload" do
          delivery = create(:webhook_delivery)

          get "/webhooks/deliveries/#{delivery.id}", headers: auth_headers
          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json["id"]).to eq(delivery.id)
          expect(json["payload"]).to be_present
          expect(json["headers"]).to be_present
        end

        it "returns 404 for missing delivery" do
          get "/webhooks/deliveries/99999", headers: auth_headers
          expect(response).to have_http_status(:not_found)
        end
      end

      describe "POST /webhooks/deliveries/:id/replay" do
        it "resets and re-enqueues delivery" do
          delivery = create(:webhook_delivery, :failed)

          post "/webhooks/deliveries/#{delivery.id}/replay", headers: auth_headers
          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json["status"]).to eq("replayed")

          delivery.reload
          expect(delivery.status).to eq("pending")
          expect(delivery.attempts).to eq(0)
        end
      end

      describe "GET /webhooks/dead_letters" do
        it "returns dead letters with delivery info" do
          delivery = create(:webhook_delivery, :dead)
          create(:dead_letter, webhook_delivery: delivery)

          get "/webhooks/dead_letters", headers: auth_headers
          expect(response).to have_http_status(:ok)
          json = JSON.parse(response.body)
          expect(json["dead_letters"].length).to eq(1)
          expect(json["dead_letters"][0]["delivery"]).to be_present
        end
      end
    end

    describe "JWT edge cases" do
      it "rejects expired JWT" do
        expired_token = generate_jwt({ exp: (Time.now - 3600).to_i })
        get "/webhooks/deliveries", headers: { "Authorization" => "Bearer #{expired_token}" }
        expect(response).to have_http_status(:unauthorized)
      end

      it "rejects JWT signed with wrong secret" do
        bad_token = generate_jwt({}, secret: "wrong_secret")
        get "/webhooks/deliveries", headers: { "Authorization" => "Bearer #{bad_token}" }
        expect(response).to have_http_status(:unauthorized)
      end

      it "rejects malformed JWT" do
        get "/webhooks/deliveries", headers: { "Authorization" => "Bearer not.a.valid.jwt" }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "GET /health" do
    it "returns health status" do
      get "/health"
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["status"]).to eq("ok")
      expect(json["timestamp"]).to be_present
    end
  end
end
