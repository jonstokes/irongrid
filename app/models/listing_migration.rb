class ListingMigration < Bellbro::Bell

  attr_accessor :listing, :es_listing, :interactor

  def initialize(listing)
    @listing = listing
  end

  def write_listing_to_index
    @interactor = retryable(sleep: 0.5) do
      WriteListingToIndex.call(
          site:         site,
          listing_json: json,
          page:         page
      )
    end
    raise "Listing #{listing.id} failed to write to index with error #{@interactor.error}." unless @interactor.success?
    @es_listing = @interactor.listing
  end

  def verify
    # Verify that listing was copied correctly here, and raise error if it wasn't.
    unless (@es_listing.url.page == page_url) && (@es_listing.url.purchase == listing.url)
      raise " Url mismatch for listing #{listing.id}:\n  ES is #{@es_listing.url}, listing is #{listing.url}, page is #{page_url}"
    end
  end

  def fix_listing_metadata
    @es_listing.updated_at = listing.updated_at.utc
    @es_listing.created_at = listing.created_at.utc
    @es_listing.image = {
        cdn: listing.image,
        download_attempted: listing.image_download_attempted,
        source: listing.item_data['image_source']
    }
    @es_listing.update_record_without_timestamping
  end

  def page
    Hashie::Mash.new(
        code: 200,
        url: page_url
    )
  end

  def json
    Hashie::Mash.new(
        valid:                    true,
        url:                      listing_url,
        engine:                   'ironsights',
        type:                     listing.type,
        title:                    listing.title,
        keywords:                 listing.keywords,
        description:              listing.description,
        condition:                listing.item_condition,
        auction_ends:             listing.auction_ends.try(:utc),
        availability:             listing.availability,
        image:                    listing.image_source,
        location:                 listing.item_location,
        discount_in_cents:        listing.discount_in_cents,
        discount_percent:         listing.discount_percent,
        shipping_cost_in_cents:   listing.shipping_cost_in_cents,
        current_price_in_cents:   listing.current_price_in_cents,
        price_on_request:         listing.price_on_request,
        price_in_cents:           listing.price_in_cents,
        sale_price_in_cents:      listing.sale_price_in_cents,
        buy_now_price_in_cents:   listing.buy_now_price_in_cents,
        current_bid_in_cents:     listing.current_bid_in_cents,
        minimum_bid_in_cents:     listing.minimum_bid_in_cents,
        reserve_in_cents:         listing.reserve_in_cents,
        product_upc:              listing.upc,
        product_sku:              listing.sku,
        product_mpn:              listing.mpn,
        product_category1:        category1,
        product_manufacturer:     listing.manufacturer,
        product_weight_shipping:  listing.weight_in_pounds.try(:to_f),
        product_caliber:          listing.caliber,
        product_caliber_category: caliber_category,
        product_number_of_rounds: listing.number_of_rounds,
        product_grains:           listing.grains
    )
  end

  def caliber_category
    return unless listing.caliber
    # Fixes for busted caliber categories
    @caliber_category ||= begin
      ListingMigration.mappings.each do |mapping_name, mapping|
        return mapping_name.split("_calibers").first if mapping.has_term?(listing.caliber, ignore_case: true)
      end
      nil
    end
  end

  def category1
    return unless listing.category1
    # Only capture hard-classified categories
    @category1 ||= begin
      category_is_hard_classified? ? listing.category1 : nil
    end
  end

  def site
    @site ||= ListingMigration.site_from_domain(listing.seller_domain)
  end

  def self.mappings
    @mappings ||= begin
      list = {}
      %w(rimfire_calibers handgun_calibers shotgun_calibers rifle_calibers).each do |key|
        list.merge!(key => Stretched::Mapping.find(key))
      end
      list
    end
  end

  def self.sites
    @sites ||= begin
      puts '# Loading sites...'
      s = IronCore::Site.all
      puts "#   #{s.count} sites loaded!"
      s
    end
  end

  def self.site_from_domain(domain)
    find_site(domain) || load_site(domain)
  end

  def self.find_site(domain)
    sites.detect do |site|
      site.domain == domain
    end
  end

  def self.load_site(domain)
    site = IronCore::Site.new(domain: domain, source: :local)
    sites << site
    site
  end

  private

  def category_is_hard_classified?
    class_type = listing.item_data['category1'].detect {|h| h['classification_type']}['classification_type']
    class_type == 'hard'
  rescue
    nil
  end

  def page_url
    # If the listing is from a feed, return that url
    # Otherwise return listing.bare_url

    @page_url ||= feed_url || listing.bare_url
  end

  def listing_url
    if feed_url
      listing.bare_url
    else
      nil
    end
  end

  def feed_url
    @feed_url ||= begin
      if site.feed_adapter
        site.sessions.first['urls'].first['url']
      else
        nil
      end
    end
  end

end