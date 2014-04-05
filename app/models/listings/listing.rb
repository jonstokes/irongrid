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
  include ListingConstants
  include Retryable
  include Notifier
  include ConnectionWrapper
  include Tire::Model::Search

  index_name Rails.env.test? ? "listings-test" : "listings"
  index.add_alias "retail_listings"
  index.add_alias "auction_listings"
  index.add_alias "classified_listings"

  after_save :update_es_index
  after_destroy :update_es_index

  validate :url, :uniqueness => true
  validate :digest, :uniqueness => true

  attr_accessible :type, :url, :digest, :inactive, :item_data, :geo_data_id, :update_count

  scope :ended_auctions, -> { where("type = ? AND item_data->>'auction_ends' < ?", "AuctionListing", (Time.now.utc - 1.day).to_s) }
  scope :no_image, -> { where("item_data->>'image_download_attempted' = ? AND updated_at > ?", 'false', 1.days.ago) }

  def to_indexed_json
    attributes_and_values = INDEXED_ATTRIBUTES.map do |attr|
      [attr.to_s, send(attr)]
    end

    Hash[attributes_and_values].merge(item_data).to_json
  end

  def activate!
    db { update_attribute(:inactive, false) }
  end

  def deactivate!
    db { update_attribute(:inactive, true) }
  end

  def image_is_shared?
    return false unless image
    db { Listing.where("id != ? AND item_data->>'image' = ?", id, image).any? }
  end

  def active?
    !inactive
  end

  def fresh?
    !stale?
  end

  def stale?
    self[:updated_at].utc < Listing.stale_threshold
  end

  def created_at
    self[:created_at].strftime("%Y-%m-%dT%H:%M:%S") if self[:created_at]
  end

  def updated_at
    self[:updated_at].strftime("%Y-%m-%dT%H:%M:%S") if self[:updated_at]
  end

  def self.find_by_image(image)
    db { Listing.where("item_data->>'image' = ?", image).first }
  end

  def self.stale_listings_for_domain(domain)
    query_conditions = "item_data->>'seller_domain' = '#{domain}'"
    db { Listing.where(query_conditions).where("updated_at < ?", stale_threshold).order("updated_at ASC").limit(400) }
  end

  def self.duplicate_digest?(listing, digest)
    db { Listing.where("id != ? AND digest = ?", listing.id, digest).any? }
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

  def self.stale_threshold
    Time.now - 24.hours
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
