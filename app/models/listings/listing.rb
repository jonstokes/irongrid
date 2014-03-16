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

class Listing < ActiveRecord::Base
  include Retryable
  include Notifier
  include ConnectionWrapper
  include Tire::Model::Search

  index_name Rails.env.test? ? "listings-test" : "listings"
  index.add_alias "retail_listings"
  index.add_alias "auction_listings"
  index.add_alias "classified_listings"

  belongs_to :geo_data
  belongs_to :site

  after_save :update_es_index
  after_destroy :update_es_index

  validate :url, :uniqueness => true
  validate :digest, :uniqueness => true
  validate :site_id, :presence => true

  attr_accessible :type, :url, :digest, :inactive, :item_data, :geo_data_id, :site_id, :update_count

  delegate *GeoData::DATA_KEYS, to: :geo_data
  delegate :domain, :name, to: :site, prefix: :seller

  scope :ended_auctions, -> { where("type = ? AND item_data->>'auction_ends' < ?", "AuctionListing", (Time.now.utc - 1.day).to_s) }

  ES_OBJECTS = %w(
    title
    category1
    caliber_category
    manufacturer
    caliber
    number_of_rounds
    grains
  )
  COMMON_ATTRIBUTES = %w(
    description
    keywords
    image
    item_condition
    item_location
    availability
    current_price_in_cents
    price_per_round_in_cents
  )
  RETAIL_ATTRIBUTES = %w(
    price_on_request
    price_in_cents
    sale_price_in_cents
  )
  CLASSIFIED_ATTRIBUTES = %w(
    price_in_cents
    sale_price_in_cents
  )
  AUCTION_ATTRIBUTES = %w(
    buy_now_price_in_cents
    current_bid_in_cents
    minimum_bid_in_cents
    reserve_in_cents
    auction_ends
  )
  TYPE_SPECIFIC_ATTRIBUTES = (RETAIL_ATTRIBUTES + CLASSIFIED_ATTRIBUTES + AUCTION_ATTRIBUTES).uniq
  ITEM_DATA_ATTRIBUTES = COMMON_ATTRIBUTES + TYPE_SPECIFIC_ATTRIBUTES

  ES_OBJECTS.each do |key|
    define_method key do
      item_data[key]
    end

    define_method "#{key}=" do |value|
      item_data_will_change! unless item_data[key] == [{key => value}]
      item_data[key] = [{key => value}]
    end
  end

  ITEM_DATA_ATTRIBUTES.each do |key|
    define_method key do
      item_data[key]
    end
    define_method "#{key}=" do |value|
      item_data_will_change! unless item_data[key] == value
      item_data[key] = value
    end
  end

  INDEXED_ATTRIBUTES = [
    :type,
    :url,
    :created_at,
    :updated_at,
    :seller_name,
    :seller_domain,
    :coordinates,
    GeoData::DATA_KEYS
  ].flatten

  def to_indexed_json
    attributes_and_values = INDEXED_ATTRIBUTES.map do |attr|
      [attr.to_s, send(attr)]
    end

    Hash[attributes_and_values].merge(item_data).to_json
  end

  def coordinates
    "#{latitude},#{longitude}"
  end

  def activate!
    db { self.update_attribute(:inactive, false) }
  end

  def deactivate!
    db { self.update_attribute(:inactive, true) }
  end

  def image_is_shared?
    return false unless image
    db { Listing.where("digest != ? AND item_data->>'image' = ?", digest, image).any? }
  end

  def active?
    !self.inactive
  end

  def created_at
    self[:created_at].strftime("%Y-%m-%dT%H:%M:%S") if self[:created_at]
  end

  def updated_at
    self[:updated_at].strftime("%Y-%m-%dT%H:%M:%S") if self[:updated_at]
  end

  def self.find_by_image(image)
    Listing.where("item_data->>'image' = ?", image).first
  end

  #
  # The following four functions are just for use in specs
  #

  def self.disable_index_updates!
    @@updates_disabled = true
  end

  def self.enable_index_updates!
    @@updates_disabled = false
  end

  def self.index_updates_disabled?
    defined?(@@updates_disabled) && @@updates_disabled
  end

  def self.recreate_index
    original_index = Tire.index(Listing.index_name).url.split(Listing.index_name).first
    Tire.configure { reset :url }
    Listing.index.delete
    ElasticTools::IndexMapping.generate(Listing.index_name)
    Listing.index.refresh
    Tire.configure { url original_index }
  end

  #
  #FIXME: Move the logic below to an interactor
  #

	def delete_with_cdn
    db { self.destroy }
    CDN.delete_image_for_listing(self) unless self.image_is_shared?
	end
	

  private

  def update_es_index
    return if Listing.index_updates_disabled?
    if inactive?
      retryable { Listing.index.remove type.downcase.sub("listing","_listing"), id }
    else
      retryable { update_index }
    end
  end
end
