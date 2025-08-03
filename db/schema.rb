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

ActiveRecord::Schema[7.1].define(version: 2025_08_03_143849) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "commissions", force: :cascade do |t|
    t.uuid "disbursement_id", null: false
    t.string "order_id", null: false
    t.decimal "commission_amount", precision: 10, scale: 2, null: false
    t.decimal "commission_rate", null: false
    t.date "commission_date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["disbursement_id", "order_id"], name: "index_commissions_on_disbursement_and_order_unique", unique: true
    t.index ["order_id"], name: "index_commissions_on_order_id", unique: true
  end

  create_table "disbursements", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "merchant_id", null: false
    t.string "frequency", null: false
    t.date "disbursement_date", null: false
    t.decimal "total_gross_amount", precision: 10, scale: 2, null: false
    t.decimal "total_commission", precision: 10, scale: 2, null: false
    t.decimal "total_net_amount", precision: 10, scale: 2, null: false
    t.string "reference", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["merchant_id"], name: "index_disbursements_on_merchant_id"
    t.index ["reference"], name: "index_disbursements_on_reference"
  end

  create_table "merchants", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "reference"
    t.string "email"
    t.date "live_on"
    t.string "disbursement_frequency"
    t.decimal "minimum_monthly_fee"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["reference"], name: "index_merchants_on_reference", unique: true
  end

  create_table "monthly_minimum_fee_defaults", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "merchant_id", null: false
    t.decimal "minimum_monthly_fee", precision: 10, scale: 2, null: false
    t.decimal "actual_commission_paid", precision: 10, scale: 2, null: false
    t.decimal "defaulted_amount", precision: 10, scale: 2, null: false
    t.date "period_date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["merchant_id", "period_date"], name: "index_monthly_minimum_fee_defaults_on_merchant_and_period", unique: true
    t.index ["merchant_id"], name: "index_monthly_minimum_fee_defaults_on_merchant_id"
  end

  create_table "orders", id: :string, default: -> { "substr(md5((random())::text), 1, 12)" }, force: :cascade do |t|
    t.string "merchant_reference"
    t.decimal "amount"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
