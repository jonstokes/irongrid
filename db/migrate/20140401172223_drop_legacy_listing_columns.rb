class DropLegacyListingColumns < ActiveRecord::Migration
  def change
    remove_column :listings, :title
    remove_column :listings, :description
    remove_column :listings, :keywords
    remove_column :listings, :item_condition
    remove_column :listings, :image
    remove_column :listings, :stock_status
    remove_column :listings, :item_location
    remove_column :listings, :price_in_cents
    remove_column :listings, :sale_price_in_cents
    remove_column :listings, :buy_now_price_in_cents
    remove_column :listings, :current_bid_in_cents
    remove_column :listings, :minimum_bid_in_cents
    remove_column :listings, :reserve_in_cents
    remove_column :listings, :price_on_request
    remove_column :listings, :auction_ends
    remove_column :listings, :engine
    remove_column :listings, :category_data
  end
end

