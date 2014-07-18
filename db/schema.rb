# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20140718194651) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "hstore"
  enable_extension "pg_stat_statements"

  create_table "geo_data", force: true do |t|
    t.string   "key"
    t.hstore   "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "geo_data", ["key"], name: "index_geo_data_on_key", unique: true, using: :btree

  create_table "listings", force: true do |t|
    t.string   "digest",                                   null: false
    t.string   "type",                                     null: false
    t.text     "url",                                      null: false
    t.datetime "created_at",                               null: false
    t.datetime "updated_at",                               null: false
    t.boolean  "inactive"
    t.integer  "update_count"
    t.json     "item_data"
    t.string   "seller_domain"
    t.datetime "auction_ends"
    t.string   "image"
    t.boolean  "image_download_attempted", default: false
    t.string   "upc"
    t.string   "mpn"
    t.string   "sku"
  end

  add_index "listings", ["auction_ends"], name: "index_listings_on_auction_ends", using: :btree
  add_index "listings", ["digest"], name: "index_listings_on_digest", unique: true, using: :btree
  add_index "listings", ["image"], name: "index_listings_on_image", using: :btree
  add_index "listings", ["inactive"], name: "index_listings_on_inactive", using: :btree
  add_index "listings", ["mpn"], name: "index_listings_on_mpn", using: :btree
  add_index "listings", ["seller_domain"], name: "index_listings_on_domain", using: :btree
  add_index "listings", ["sku"], name: "index_listings_on_sku", using: :btree
  add_index "listings", ["upc"], name: "index_listings_on_upc", using: :btree
  add_index "listings", ["updated_at"], name: "index_listings_on_updated_at", using: :btree
  add_index "listings", ["url"], name: "index_listings_on_url", unique: true, using: :btree

  create_table "log_records", force: true do |t|
    t.json     "data",       null: false
    t.string   "agent",      null: false
    t.string   "jid",        null: false
    t.boolean  "archived"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "domain"
  end

  add_index "log_records", ["archived"], name: "index_log_records_on_archived", using: :btree
  add_index "log_records", ["domain"], name: "index_log_records_on_domain", using: :btree
  add_index "log_records", ["jid"], name: "index_log_records_on_jid", unique: true, using: :btree

  create_table "parser_tests", force: true do |t|
    t.string   "engine"
    t.string   "source_url"
    t.string   "seller_domain"
    t.string   "category2"
    t.string   "html_on_s3"
    t.boolean  "is_valid"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.boolean  "not_found"
    t.boolean  "classified_sold"
    t.json     "listing_data"
  end

  create_table "rails_admin_histories", force: true do |t|
    t.text     "message"
    t.string   "username"
    t.integer  "item"
    t.string   "table"
    t.integer  "month",      limit: 2
    t.integer  "year",       limit: 8
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "rails_admin_histories", ["item", "table", "month", "year"], name: "index_rails_admin_histories", using: :btree

  create_table "sites", force: true do |t|
    t.string   "name",                null: false
    t.string   "domain",              null: false
    t.text     "adapter_source",      null: false
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
    t.string   "engine"
    t.string   "scrape_with_service"
    t.text     "service_options"
    t.integer  "size"
    t.boolean  "active"
    t.text     "rate_limits"
    t.datetime "read_at"
    t.integer  "read_interval"
    t.string   "commit_sha"
  end

  create_table "users", force: true do |t|
    t.string   "email",                  default: "",    null: false
    t.string   "encrypted_password",     default: "",    null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,     null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "admin",                  default: false
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

end
