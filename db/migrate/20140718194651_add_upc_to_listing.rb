class AddUpcToListing < ActiveRecord::Migration
  def change
    add_column :listings, :upc, :string
    add_column :listings, :mpn, :string
    add_column :listings, :sku, :string

    add_index "listings", ["upc"], name: "index_listings_on_upc", unique: false, using: :btree
    add_index "listings", ["mpn"], name: "index_listings_on_mpn", unique: false, using: :btree
    add_index "listings", ["sku"], name: "index_listings_on_sku", unique: false, using: :btree
  end
end
