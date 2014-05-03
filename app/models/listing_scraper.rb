class ListingScraper < CoreModel
  attr_reader :site, :doc, :clean_listing, :adapter
  attr_accessor :raw_listing, :listing

  delegate :name, :domain, to: :site, prefix: :seller

  def initialize(site)
    @site = site
  end

  def parse(opts)
    empty!
    @doc = opts[:doc]
    @adapter = (opts[:adapter_type] == :feed) ? @site.feed_adapter : @site.page_adapter
    @raw_listing = RawListing.new(opts.merge(adapter: @adapter))
    return if not_found?
    @clean_listing = eval("#{type}Cleaner").new(
      raw_listing: @raw_listing,
      site:        @site,
      url:         opts[:url],
      adapter:     @adapter
    )
  end

  def listing
    @clean_listing.to_h
  end

  def empty!
    @raw_listing = @clean_listing = nil
  end

  def type
    basic_type = raw_listing['listing_type'] ? raw_listing['listing_type'].capitalize : adapter.default_listing_type.capitalize
    "#{basic_type}Listing"
  end

  def is_valid?
    !not_found? && @clean_listing.is_valid?
  end

  def not_found?
    !!raw_listing['not_found']
  end

  def classified_sold?
    @clean_listing.classified_sold?
  rescue NoMethodError
    false
  end
end
