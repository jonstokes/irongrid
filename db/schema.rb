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

ActiveRecord::Schema.define(version: 20140327132319) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "hstore"

  create_table "geo_data", force: true do |t|
    t.string   "key"
    t.hstore   "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "geo_data", ["key"], name: "index_geo_data_on_key", unique: true, using: :btree

  create_table "job_records", force: true do |t|
    t.string   "domain"
    t.integer  "links_crawled"
    t.integer  "pages_created"
    t.integer  "pages_deleted"
    t.boolean  "complete"
    t.integer  "listings_created"
    t.integer  "listings_updated"
    t.integer  "listings_deleted"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
    t.string   "worker"
    t.integer  "listings_read"
    t.boolean  "archived"
    t.integer  "links_created"
    t.integer  "links_deleted"
  end

  create_table "listings", force: true do |t|
    t.string   "digest",       null: false
    t.string   "type",         null: false
    t.text     "url",          null: false
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.boolean  "inactive"
    t.integer  "update_count"
    t.integer  "geo_data_id"
    t.json     "item_data"
    t.integer  "site_id"
  end

  add_index "listings", ["digest"], name: "index_listings_on_digest", unique: true, using: :btree
  add_index "listings", ["url"], name: "index_listings_on_url", unique: true, using: :btree

  create_table "log_records", force: true do |t|
    t.json     "data",       null: false
    t.string   "agent",      null: false
    t.string   "jid",        null: false
    t.boolean  "archived"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "log_records", ["jid"], name: "index_job_records_on_jid", unique: true, using: :btree

  create_table "parser_tests", force: true do |t|
    t.string   "engine"
    t.string   "url"
    t.string   "digest"
    t.text     "title"
    t.text     "description"
    t.text     "keywords"
    t.string   "listing_type"
    t.string   "seller_domain"
    t.string   "seller_name"
    t.string   "category1"
    t.string   "category2"
    t.string   "item_condition"
    t.string   "image"
    t.string   "stock_status"
    t.string   "item_location"
    t.integer  "price_in_cents"
    t.string   "price_on_request"
    t.integer  "sale_price_in_cents"
    t.integer  "buy_now_price_in_cents"
    t.integer  "current_bid_in_cents"
    t.integer  "minimum_bid_in_cents"
    t.integer  "reserve_in_cents"
    t.datetime "auction_ends"
    t.string   "html_on_s3"
    t.boolean  "listing_is_valid"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.boolean  "not_found"
    t.boolean  "item_sold"
    t.string   "caliber"
    t.integer  "number_of_rounds"
    t.integer  "grains"
    t.string   "manufacturer"
    t.string   "model"
  end

  create_table "service_records", force: true do |t|
    t.string   "service"
    t.string   "main_thread_status"
    t.string   "tracker_thread_status"
    t.text     "batch_status"
    t.datetime "created_at",            null: false
    t.datetime "updated_at",            null: false
    t.string   "host"
    t.text     "thread_error"
    t.text     "tracker_error"
    t.boolean  "archived"
  end

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

end
