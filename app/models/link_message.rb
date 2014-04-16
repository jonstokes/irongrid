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
    :listing_digest,
    :listing_id,
    :dirty_only
  ]

  LINK_MESSAGE_KEYS.each do |key|
    define_method(key) { @data[key] } #getters
    define_method("#{key}=") { |value| @data[key] = value } #setters
    if [:page_is_valid, :page_not_found, :dirty_only].include?(key) #status
      define_method("#{key}?") { @data[key] }
    end
  end

  def initialize(attrs)
    new_from_hash(attrs) if attrs.is_a?(Hash)
    new_from_listing(attrs) if attrs.is_a?(Listing)
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
      url:            listing.url,
      listing_id:     listing.id,
      listing_digest: listing.digest,
    }
  end

  def check_attributes(attrs)
    attrs.keys.each { |a| raise "Invalid attribute #{a}" unless (LINK_MESSAGE_KEYS).include?(a) }
  end
end