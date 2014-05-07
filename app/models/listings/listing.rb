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
  scope :active, -> { where(inactive: [nil, false]) }
  scope :inactive, -> { where(inactive: true) }

  def to_indexed_json
    attributes_and_values = INDEXED_ATTRIBUTES.map do |attr|
      [attr.to_s, send(attr)]
    end

    Hash[attributes_and_values].merge(item_data).to_json
  end

  def url
    "#{self[:url]}#{affiliate_link_tag}"
  end

  def bare_url
    self[:url]
  end

  def update_and_dirty!(attrs)
    attrs.merge!(update_count: self.dirty)
    new_item_data = update_item_data(attrs['item_data'])
    attrs.merge!(item_data: new_item_data)
    self.item_data_will_change!
    db { self.update(attrs) }
  end

  def activate!
    self.inactive = false
    self.dirty
    db { self.save! }
  end

  def deactivate!
    self.inactive = true
    self.dirty
    db { self.save! }
  end

  def dirty
    self.update_count = (self.update_count || 0) + 1
  end

  def dirty!
    self.dirty
    @dirtied = true
    db { self.save! }
  end

  def dirtied?
    !!@dirtied
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

  def self.register_percolator(percolator_name, json_query)
    Listing.index.register_percolator_query_as_json(percolator_name, json_query)
  end

  def self.unregister_percolator(percolator_name)
    Listing.index.unregister_percolator_query(percolator_name)
  end

  def self.find_by_image(image)
    db { Listing.where("item_data->>'image' = ?", image).first }
  end

  def self.duplicate_digest?(listing, digest)
    db { Listing.where("id != ? AND digest = ?", listing.id, digest).any? }
  end

  def self.with_each_stale_listing_for_domain(domain)
    query_conditions = "item_data->>'seller_domain' = '#{domain}'"
    db do
      Listing.where(query_conditions).where("updated_at < ?", stale_threshold).order("updated_at ASC").find_each(batch_size: 200) do |listing|
        yield listing
      end
    end
  end

  def self.stalest_for_domain(domain)
    db { Listing.where("item_data->>'seller_domain' = ?", domain).order("updated_at ASC").limit(1).try(:first) }
  end

  def self.active_count_for_domain(domain)
    db { Listing.active.where("item_data->>'seller_domain' = ?", domain).count }
  end

  def self.inactive_count_for_domain(domain)
    db { Listing.inactive.where("item_data->>'seller_domain' = ?", domain).count }
  end

  def self.stale_count_for_domain(domain)
    db { Listing.where("item_data->>'seller_domain' = ? AND updated_at < ?", domain, stale_threshold).count }
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

  def self.stale_threshold
    Time.now - 24.hours
  end

  private

  def update_item_data(new_item_data)
    final_item_data = update_es_objects(new_item_data, item_data.dup)
    udpate_other_item_data(new_item_data, final_item_data)
  end

  def update_es_objects(new_item_data, final_item_data)
    ES_OBJECTS.each do |attr|
      if should_overwrite_attribute?(new_item_data, attr)
        final_item_data.merge!(attr => new_item_data[attr])
      end
    end
    final_item_data
  end

  def udpate_other_item_data(new_item_data, final_item_data)
    ITEM_DATA_ATTRIBUTES.each do |attr|
      final_item_data.merge!(attr => new_item_data[attr]) if attr[/price/] || new_item_data[attr].present?
    end
    final_item_data
  end

  def should_overwrite_attribute?(new_item_data, attr)
    original_classification_type = read_classification_type(item_data, attr)
    new_classification_type = read_classification_type(new_item_data, attr)
    (new_classification_type == 'hard') ||
      ((original_classification_type == 'soft') && (new_classification_type == 'metadata'))
  end

  def read_classification_type(item_data_hash, attr)
    item_data_hash[attr].detect { |v| v['classification_type'] }.try(:[], 'classification_type') rescue nil
  end

  def notify_on_match
    percolate.each do |match|
      SearchAlertQueues.push(listing_id: self.id, percolator_name: match['_id'])
    end
  end

  def update_es_index
    return if Listing.index_updates_disabled?
    if inactive?
      retryable { Listing.index.remove type.downcase.sub("listing","_listing"), id }
    else
      retryable { update_index }
      retryable { notify_on_match } unless dirtied? || destroyed? || !self.digest_changed?
    end
  end
end
