class ParserTestToJson < ActiveRecord::Migration
  def change
    add_column :parser_tests, :listing_data, :json

    rename_column :parser_tests, :url, :source_url
    rename_column :parser_tests, :listing_is_valid, :is_valid
    rename_column :parser_tests, :item_sold, :classified_sold

    remove_column :parser_tests, :reserve_in_cents
    remove_column :parser_tests, :auction_ends
    remove_column :parser_tests, :buy_now_price_in_cents
    remove_column :parser_tests, :category1
    remove_column :parser_tests, :current_bid_in_cents
    remove_column :parser_tests, :description
    remove_column :parser_tests, :digest
    remove_column :parser_tests, :image
    remove_column :parser_tests, :item_condition
    remove_column :parser_tests, :item_location
    remove_column :parser_tests, :keywords
    remove_column :parser_tests, :listing_type
    remove_column :parser_tests, :minimum_bid_in_cents
    remove_column :parser_tests, :price_in_cents
    remove_column :parser_tests, :price_on_request
    remove_column :parser_tests, :sale_price_in_cents
    remove_column :parser_tests, :seller_name
    remove_column :parser_tests, :stock_status
    remove_column :parser_tests, :title
    remove_column :parser_tests, :manufacturer
    remove_column :parser_tests, :grains
    remove_column :parser_tests, :number_of_rounds
    remove_column :parser_tests, :caliber_category
    remove_column :parser_tests, :caliber
  end
end
