FactoryBot.define do
  factory :webhook_delivery do
    provider { "github" }
    sequence(:delivery_id) { |n| "delivery-#{n}" }
    event_type { "push" }
    payload { { ref: "refs/heads/main", repository: { full_name: "owner/repo" }, commits: [] } }
    headers { { "HTTP_X_GITHUB_EVENT" => "push" } }
    status { :pending }
    attempts { 0 }

    trait :processing do
      status { :processing }
    end

    trait :completed do
      status { :completed }
      processed_at { Time.current }
    end

    trait :failed do
      status { :failed }
      attempts { 2 }
      error_message { "RuntimeError: Something went wrong" }
    end

    trait :dead do
      status { :dead }
      attempts { 3 }
      error_message { "RuntimeError: Fatal error" }
    end

    trait :stripe do
      provider { "stripe" }
      event_type { "payment_intent.succeeded" }
      payload { { id: "evt_123", type: "payment_intent.succeeded", data: { object: { amount: 2000, currency: "usd", status: "succeeded" } } } }
      headers { { "HTTP_STRIPE_SIGNATURE" => "t=123,v1=abc" } }
    end

    trait :generic do
      provider { "generic" }
      event_type { "user.created" }
      payload { { event: "user.created", data: { user_id: 1 } } }
    end
  end
end
