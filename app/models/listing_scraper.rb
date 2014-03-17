class ListingScraper < CoreModel
  attr_reader :site, :doc, :clean_listing
  attr_accessor :raw_listing, :listing

  def initialize(site)
    @site = site
    @site.init if @site.adapter.nil?
  end

  def parse(opts)
    empty!
    url = opts[:url]
    @doc = opts[:doc]
    @raw_listing = RawListing.new(opts.merge(site: @site))
    return if not_found?
    @clean_listing = eval("#{type}Cleaner").new(raw_listing: @raw_listing, site: @site, url: url)
  end

  def listing
    @clean_listing.to_h
  end

  def empty!
    @raw_listing = @clean_listing = nil
  end

  def type
    basic_type = raw_listing['listing_type'] ? raw_listing['listing_type'].capitalize : site.default_listing_type.capitalize
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

  def seller_domain
    site.domain
  end

  #
  # Logging
  #

  def clean_terminal_dump
    puts "##################################"
    puts "Is valid? #{is_valid?}"
    @listing.each do |attr, value|
      puts "#{attr}: #{value || 'nil'}"
    end
    puts "Auction ended? #{auction_ended?}"
    puts "Classifed sold? #{classified_sold?}"
    puts "Not found? #{not_found?}"
    puts "##################################"
  end

  def raw_terminal_dump
    puts "##################################"
    @raw_listing.each do |attr, value|
      puts "#{attr}: #{value || 'nil'}"
    end
    puts "##################################"
  end

  def log
    Rails.logger.debug "########## CLEAN #######################"
    Rails.logger.debug "## THREAD ID: #{Thread.current.object_id}"
    @listing.each do |attr, value|
      Rails.logger.debug "## #{attr}: #{value || 'nil'}"
    end
    Rails.logger.debug "## Auction ended? #{auction_ended?}"
    Rails.logger.debug "## Classifed sold? #{classified_sold?}"
    Rails.logger.debug "## Not found? #{not_found?}"
    Rails.logger.debug "##################################"
  end

  def raw_log
    Rails.logger.debug "########## RAW #######################"
    @raw_listing.each do |attr, value|
      Rails.logger.debug "## #{attr}: #{value || 'nil'}"
    end
    Rails.logger.debug "##################################"
  end

  def raw_puts
    puts "########## RAW #######################"
    @raw_listing.each do |attr, value|
      puts "## #{attr}: #{value || 'nil'}"
    end
    puts "##################################"
  end
end
