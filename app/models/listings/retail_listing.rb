# == Schema Information
#
# Table name: listings
#
#  id                     :integer          not null, primary key
#  title                  :text             not null
#  description            :text
#  keywords               :text
#  digest                 :string(255)      not null
#  type                   :string(255)      not null
#  seller_domain          :string(255)      not null
#  seller_name            :string(255)      not null
#  url                    :text             not null
#  category1              :string(255)
#  category2              :string(255)
#  item_condition         :string(255)
#  image                  :string(255)      not null
#  stock_status           :string(255)
#  item_location          :string(255)
#  price_in_cents         :integer
#  sale_price_in_cents    :integer
#  buy_now_price_in_cents :integer
#  current_bid_in_cents   :integer
#  minimum_bid_in_cents   :integer
#  reserve_in_cents       :integer
#  auction_ends           :datetime
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  price_on_request       :string(255)
#  engine                 :string(255)
#  inactive               :boolean
#  update_count           :integer
#  geo_data_id            :integer
#  category_data          :hstore
#

class RetailListing < Listing
  index_name superclass.index_name
end
