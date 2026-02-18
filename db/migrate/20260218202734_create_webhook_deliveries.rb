class CreateWebhookDeliveries < ActiveRecord::Migration[8.1]
  def change
    create_table :webhook_deliveries do |t|
      t.string :provider, null: false
      t.string :delivery_id, null: false
      t.string :event_type
      t.json :payload, default: {}
      t.json :headers, default: {}
      t.integer :status, default: 0, null: false
      t.integer :attempts, default: 0, null: false
      t.text :error_message
      t.datetime :processed_at

      t.timestamps
    end

    add_index :webhook_deliveries, :delivery_id, unique: true
    add_index :webhook_deliveries, :provider
    add_index :webhook_deliveries, :status
    add_index :webhook_deliveries, :created_at
  end
end
