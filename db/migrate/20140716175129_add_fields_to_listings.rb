class AddFieldsToListings < ActiveRecord::Migration
  def change
    add_column :listings, :seller_domain,            :string
    add_column :listings, :auction_ends,             :datetime
    add_column :listings, :image,                    :string
    add_column :listings, :image_download_attempted, :boolean, default: false

    add_index "listings", ["seller_domain"], name: "index_listings_on_domain",       unique: false, using: :btree
    add_index "listings", ["image"],         name: "index_listings_on_image",        unique: false, using: :btree
    add_index "listings", ["auction_ends"],  name: "index_listings_on_auction_ends", unique: false, using: :btree
    add_index "listings", ["updated_at"],    name: "index_listings_on_updated_at",   unique: false, using: :btree
    add_index "listings", ["inactive"],      name: "index_listings_on_inactive",     unique: false, using: :btree

    add_column :log_records, :domain, :string

    add_index "log_records", ["domain"],   name: "index_log_records_on_domain",   unique: false, using: :btree
    add_index "log_records", ["archived"], name: "index_log_records_on_archived", unique: false, using: :btree
  end
end
