Rails.application.routes.draw do
  post "/webhooks/:provider", to: "webhooks#receive"

  scope "/webhooks" do
    get "/deliveries", to: "webhooks#index"
    get "/deliveries/:id", to: "webhooks#show"
    post "/deliveries/:id/replay", to: "webhooks#replay"
    get "/dead_letters", to: "webhooks#dead_letters"
  end

  get "/health", to: "health#show"
end
