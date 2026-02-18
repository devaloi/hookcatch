class CreateDeadLetters < ActiveRecord::Migration[8.1]
  def change
    create_table :dead_letters do |t|
      t.references :webhook_delivery, null: false, foreign_key: true
      t.string :error_class
      t.text :error_message
      t.text :backtrace
      t.datetime :failed_at

      t.timestamps
    end
  end
end
