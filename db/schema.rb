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

ActiveRecord::Schema[7.0].define(version: 2025_10_28_074118) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "bill_line_items", force: :cascade do |t|
    t.bigint "bill_id", null: false
    t.bigint "item_id", null: false
    t.string "name", null: false
    t.integer "qty", default: 1, null: false
    t.integer "unit_price_cents", null: false
    t.integer "claimed_qty", default: 0, null: false
    t.integer "subtotal_cents", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bill_id"], name: "index_bill_line_items_on_bill_id"
    t.index ["item_id"], name: "index_bill_line_items_on_item_id"
    t.check_constraint "claimed_qty <= qty"
  end

  create_table "bills", force: :cascade do |t|
    t.bigint "table_id", null: false
    t.string "currency", default: "ron", null: false
    t.integer "tax_rate_bps", default: 0, null: false
    t.integer "service_fee_bps", default: 0, null: false
    t.integer "tip_mode", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.datetime "snapshot_at"
    t.integer "subtotal_cents", default: 0, null: false
    t.integer "tax_cents", default: 0, null: false
    t.integer "fees_cents", default: 0, null: false
    t.integer "tip_cents", default: 0, null: false
    t.integer "total_cents", default: 0, null: false
    t.integer "paid_cents", default: 0, null: false
    t.integer "remaining_cents", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "venue_id", null: false
    t.index ["table_id"], name: "index_bills_on_table_id"
  end

  create_table "checkout_sessions", force: :cascade do |t|
    t.bigint "claim_id", null: false
    t.string "stripe_checkout_session_id"
    t.string "stripe_payment_intent_id"
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["claim_id"], name: "index_checkout_sessions_on_claim_id"
  end

  create_table "claim_units", force: :cascade do |t|
    t.bigint "claim_id", null: false
    t.bigint "bill_line_item_id", null: false
    t.integer "qty", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bill_line_item_id"], name: "index_claim_units_on_bill_line_item_id"
    t.index ["claim_id", "bill_line_item_id"], name: "index_claim_units_on_claim_id_and_bill_line_item_id", unique: true
    t.index ["claim_id"], name: "index_claim_units_on_claim_id"
  end

  create_table "claims", force: :cascade do |t|
    t.bigint "bill_id", null: false
    t.bigint "user_id"
    t.integer "claim_type", default: 0, null: false
    t.integer "state", default: 0, null: false
    t.integer "amount_subtotal_cents", default: 0, null: false
    t.integer "tax_cents", default: 0, null: false
    t.integer "fees_cents", default: 0, null: false
    t.integer "tip_cents", default: 0, null: false
    t.integer "amount_total_cents", default: 0, null: false
    t.datetime "expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bill_id"], name: "index_claims_on_bill_id"
    t.index ["user_id"], name: "index_claims_on_user_id"
  end

  create_table "item_table_relations", force: :cascade do |t|
    t.bigint "item_id"
    t.bigint "table_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "items", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "price_cents", default: 0, null: false
    t.bigint "venue_id", null: false
  end

  create_table "payments", force: :cascade do |t|
    t.string "status"
    t.string "payment_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "amount_cents", default: 0, null: false
  end

  create_table "tables", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "venue_id", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "jti", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["jti"], name: "index_users_on_jti", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "venues", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug", null: false
    t.string "address"
    t.string "currency", default: "ron"
    t.string "stripe_account_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_venues_on_slug", unique: true
  end

  add_foreign_key "bill_line_items", "bills"
  add_foreign_key "bill_line_items", "items"
  add_foreign_key "bills", "tables"
  add_foreign_key "bills", "venues"
  add_foreign_key "checkout_sessions", "claims"
  add_foreign_key "claim_units", "bill_line_items"
  add_foreign_key "claim_units", "claims"
  add_foreign_key "claims", "bills"
  add_foreign_key "claims", "users"
  add_foreign_key "items", "venues"
  add_foreign_key "tables", "venues"
end
