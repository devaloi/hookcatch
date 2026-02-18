FactoryBot.define do
  factory :dead_letter do
    webhook_delivery
    error_class { "RuntimeError" }
    error_message { "Something went wrong" }
    backtrace { "app/handlers/test.rb:10\napp/services/processor.rb:20" }
    failed_at { Time.current }
  end
end
