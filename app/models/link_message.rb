#
# This class is used instead of a regular hash in order to provide
# a consistent interface with some error checking for how the workers
# pass data about links to each other
#

class LinkMessage

  LINK_MESSAGE_KEYS = [
    :url,
    :jid,
    :page_attributes,
    :page_is_valid,
    :page_not_found,
    :page_classified_sold,
    :raw_attributes,
    :listing_digest,
    :listing_id,
    :dirty_only
  ]

  LINK_MESSAGE_KEYS.each do |key|
    define_method(key) { @data[key] } #getters
    define_method("#{key}=") { |value| @data[key] = value } #setters
    if [:page_is_valid, :page_not_found, :dirty_only, :page_classified_sold].include?(key) #status
      define_method("#{key}?") { @data[key] }
    end
  end

  def initialize(attrs)
    new_from_hash(attrs) if attrs.is_a?(Hash)
    new_from_listing(attrs) if attrs.is_a?(Listing)
    new_from_scraper(attrs) if attrs.is_a?(WriteJsonToIndex)
  end

  def update(attrs)
    attrs.symbolize_keys!
    check_attributes(attrs)
    @data.merge!(attrs)
  end

  def to_h
    @data
  end

  def empty?
    @data.empty?
  end

  private

  def new_from_hash(attrs)
    attrs.symbolize_keys!
    check_attributes(attrs)
    @data = attrs.dup
  end

  def new_from_listing(listing)
    @data = {
      url:            listing.bare_url,
      listing_id:     listing.id,
      listing_digest: listing.digest,
    }
  end

  def new_from_scraper(scraper)
    @data = {
      url:             scraper.url,
      page_is_valid:   scraper.is_valid?,
      page_not_found:  scraper.not_found?,
      page_attributes: scraper.listing.try(:to_hash)
    }
  end

  def check_attributes(attrs)
    attrs.keys.each { |a| raise "Invalid attribute #{a}" unless (LINK_MESSAGE_KEYS).include?(a) }
  end
end
