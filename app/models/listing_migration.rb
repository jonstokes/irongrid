class ListingMigration
  include Retryable
  include Notifier

  attr_accessor :listing

  def initialize(listing)
    @listing = opts[:listing]
  end

  def write_json_to_index
    result = WriteListingToIndex.call(
        site:         site,
        listing_json: json,
        page:         page
    )
    raise "Listing #{listing.id} failed to write to index." unless result.success?
    @es_listing = result.listing
  end

  def fix_listing_metadata
    IronBase::Listing.record_timestamps = false
    @es_listing.update(
        created_at: listing.created_at.utc,
        updated_at: listing.updated_at.utc,
        image: {
            cdn: listing.cdn_image,
            download_attempted: listing.image_download_attempted,
            source: listing.image_source
        }
    )
    @es_listing.save
    IronBase::Listing.record_timestamps = true
  end

  def page
    {
        code: 200,
        url: page_url
    }
  end

  def json
    {
        url:                      listing_url,
        engine:                   'ironsights',
        type:                     listing.type,
        title:                    listing.title,
        keywords:                 listing.keywords,
        description:              listing.description,
        condition:                listing.item_condition,
        auction_ends:             listing.auction_ends.utc,
        availability:             listing.availability,
        image:                    listing.image_source,
        location:                 listing.item_location,
        discount_in_cents:        listing.discount_in_cents,
        discount_percent:         listing.discount_percent,
        shipping_cost_in_cents:   listing.shipping_cost_in_cents,
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
        product_weight_shipping:  listing.weight_in_pounds,
        product_caliber:          listing.caliber,
        product_caliber_category: caliber_category,
        product_number_of_rounds: listing.number_of_rounds,
        product_grains:           listing.grains
    }
  end

  def caliber_category
    @caliber_category ||= begin
      ListingMigration.mappings.each do |mapping_name, mapping|
        return mapping_name.split("_calibers").first if mapping.has_term?(caliber, ignore_case: true)
      end
      nil
    end
  end

  def category1
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
      s = Site.all
      puts "#   #{s.count} sites loaded!"
      s
    end
  end

  def self.site_from_domain(domain)
    sites.detect do |site|
      site.domain == domain
    end
  end

  private

  def category_is_hard_classified?
    class_type = listing.item_data['category1'].detect {|h| h['classification_type']}['classification_type']
    %w(hard metadata).include?(class_type)
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
        site.sessions.first.urls.first.url
      else
        nil
      end
    end
  end

end