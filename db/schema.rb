# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_02_18_202738) do
  create_table "dead_letters", force: :cascade do |t|
    t.text "backtrace"
    t.datetime "created_at", null: false
    t.string "error_class"
    t.text "error_message"
    t.datetime "failed_at"
    t.datetime "updated_at", null: false
    t.integer "webhook_delivery_id", null: false
    t.index ["webhook_delivery_id"], name: "index_dead_letters_on_webhook_delivery_id"
  end

  create_table "webhook_deliveries", force: :cascade do |t|
    t.integer "attempts", default: 0, null: false
    t.datetime "created_at", null: false
    t.string "delivery_id", null: false
    t.text "error_message"
    t.string "event_type"
    t.json "headers", default: {}
    t.json "payload", default: {}
    t.datetime "processed_at"
    t.string "provider", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_webhook_deliveries_on_created_at"
    t.index ["delivery_id"], name: "index_webhook_deliveries_on_delivery_id", unique: true
    t.index ["provider"], name: "index_webhook_deliveries_on_provider"
    t.index ["status"], name: "index_webhook_deliveries_on_status"
  end

  add_foreign_key "dead_letters", "webhook_deliveries"
end
