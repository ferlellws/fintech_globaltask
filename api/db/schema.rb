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

ActiveRecord::Schema[8.1].define(version: 2026_02_27_185800) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "audit_logs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "credit_application_id", null: false
    t.string "new_status"
    t.string "old_status"
    t.datetime "updated_at", null: false
    t.index ["credit_application_id"], name: "index_audit_logs_on_credit_application_id"
  end

  create_table "credit_applications", force: :cascade do |t|
    t.datetime "application_date"
    t.jsonb "banking_information"
    t.string "country"
    t.datetime "created_at", null: false
    t.string "full_name"
    t.string "identity_document"
    t.decimal "monthly_income"
    t.decimal "requested_amount"
    t.string "status"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["application_date"], name: "index_credit_applications_on_application_date"
    t.index ["banking_information"], name: "index_credit_applications_on_banking_information", using: :gin
    t.index ["country", "identity_document"], name: "idx_unique_pending_credit_apps", unique: true, where: "((status)::text = 'pending'::text)"
    t.index ["country", "status"], name: "idx_credit_apps_country_status"
    t.index ["country"], name: "index_credit_applications_on_country"
    t.index ["created_at"], name: "index_credit_applications_on_created_at"
    t.index ["status", "created_at"], name: "idx_credit_apps_status_created_at", order: { created_at: :desc }
    t.index ["status"], name: "index_credit_applications_on_status"
    t.index ["user_id"], name: "index_credit_applications_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.string "password_digest"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "audit_logs", "credit_applications"
  add_foreign_key "credit_applications", "users"
end
