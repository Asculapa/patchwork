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

ActiveRecord::Schema[8.1].define(version: 2026_09_11_120600) do
  create_table "entries", force: :cascade do |t|
    t.string "author"
    t.text "content_html"
    t.datetime "created_at", null: false
    t.string "fingerprint"
    t.string "guid", null: false
    t.string "image_url"
    t.json "media", default: {}, null: false
    t.datetime "published_at", null: false
    t.integer "source_id", null: false
    t.text "summary"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.string "url"
    t.index ["fingerprint"], name: "index_entries_on_fingerprint"
    t.index ["source_id", "guid"], name: "index_entries_on_source_id_and_guid", unique: true
    t.index ["source_id", "published_at"], name: "index_entries_on_source_id_and_published_at"
  end

  create_table "fetch_logs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "duration_ms"
    t.text "error"
    t.integer "http_status"
    t.integer "new_entries_count", default: 0, null: false
    t.integer "source_id", null: false
    t.string "status", null: false
    t.index ["source_id", "created_at"], name: "index_fetch_logs_on_source_id_and_created_at"
  end

  create_table "groups", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id", "name"], name: "index_groups_on_user_id_and_name", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "sources", force: :cascade do |t|
    t.json "config", default: {}, null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "error_count", default: 0, null: false
    t.string "etag"
    t.integer "fetch_interval", default: 3600, null: false
    t.string "icon_url"
    t.string "kind", default: "feed", null: false
    t.text "last_error"
    t.datetime "last_fetched_at"
    t.string "last_modified"
    t.datetime "next_fetch_at"
    t.integer "owner_id"
    t.string "site_url"
    t.string "status", default: "active", null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.string "url", null: false
    t.string "visibility", default: "shared", null: false
    t.index ["owner_id"], name: "index_sources_on_owner_id"
    t.index ["status", "next_fetch_at"], name: "index_sources_on_status_and_next_fetch_at"
    t.index ["url"], name: "index_sources_on_url", unique: true, where: "visibility = 'shared'"
  end

  create_table "subscriptions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "custom_title"
    t.integer "group_id"
    t.boolean "muted", default: false, null: false
    t.integer "source_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["group_id"], name: "index_subscriptions_on_group_id"
    t.index ["source_id"], name: "index_subscriptions_on_source_id"
    t.index ["user_id", "source_id"], name: "index_subscriptions_on_user_id_and_source_id", unique: true
  end

  create_table "user_entries", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "entry_id", null: false
    t.datetime "published_at", null: false
    t.datetime "read_at"
    t.datetime "starred_at"
    t.integer "subscription_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["entry_id"], name: "index_user_entries_on_entry_id"
    t.index ["subscription_id", "read_at"], name: "index_user_entries_on_subscription_id_and_read_at"
    t.index ["user_id", "entry_id"], name: "index_user_entries_on_user_id_and_entry_id", unique: true
    t.index ["user_id", "read_at", "published_at"], name: "index_user_entries_on_user_id_and_read_at_and_published_at"
    t.index ["user_id", "starred_at"], name: "index_user_entries_on_user_id_and_starred_at"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.string "time_zone", default: "UTC", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "entries", "sources", on_delete: :cascade
  add_foreign_key "fetch_logs", "sources", on_delete: :cascade
  add_foreign_key "groups", "users", on_delete: :cascade
  add_foreign_key "sessions", "users"
  add_foreign_key "sources", "users", column: "owner_id", on_delete: :cascade
  add_foreign_key "subscriptions", "groups", on_delete: :nullify
  add_foreign_key "subscriptions", "sources"
  add_foreign_key "subscriptions", "users", on_delete: :cascade
  add_foreign_key "user_entries", "entries", on_delete: :cascade
  add_foreign_key "user_entries", "subscriptions", on_delete: :cascade
  add_foreign_key "user_entries", "users", on_delete: :cascade
end
