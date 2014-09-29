class ParserTest < ActiveRecord::Base
  include PageUtils
  include Retryable

  attr_accessible :source_url, :seller_domain, :is_valid, :not_found, :classified_sold, :html_on_s3, :should_send_to_s3
  attr_accessible :listing_data
  attr_reader :scraper

  attr_accessor :scrape_errors

  before_save :send_html_to_s3

  LISTING_DATA_ATTRIBUTES = Listing::ES_OBJECTS + Listing::ITEM_DATA_ATTRIBUTES

  Listing::ES_OBJECTS.each do |key|
    define_method key do
      listing_data['item_data'][key].detect { |attr| attr[key] }.try(:[], key) if listing_data.present?
    end
  end

  Listing::ITEM_DATA_ATTRIBUTES.each do |key|
    next if %w(seller_domain type).include?(key)
    define_method key do
      listing_data['item_data'][key] if listing_data.present?
    end
  end

  %w(url digest).each do |key|
    define_method key do
      listing_data[key] if listing_data.present?
    end
  end

  def domain
    seller_domain || URI(source_location).host
  end

  def listing_type
    listing_data['type'] if listing_data.present?
  end

  def fetch_page
    session = {
      queue: domain,
      session_definition: 'globals/standard_html_session',
      object_adapters: [ "#{domain}/product_page" ],
      urls: [{ url: source_location }]
    }.to_yaml
    worker = ScrapePageWorker.new
    @scraper = worker.perform(
      domain:      domain,
      session:     session,
      site_source: :local
    )
  end


  def stretched_listing_queue
     @scraper["#{domain}/listings"].try(:first)
  end

  def stretched_json
    return unless stretched_listing_queue && stretched_listing_queue[:json]
    stretched_listing_queue[:json].object
  end

  def irongrid_listing
    stretched_listing_queue[:listing]
  end

  def source_location
    html_on_s3.present? ? html_on_s3 : source_url
  end

  def should_send_to_s3
    @should_send_to_s3 == "1"
  end

  def should_send_to_s3=(value)
    @should_send_to_s3 = value
  end

  def update_listing_data!
    not_found = stretched_json.not_found?
    is_valid = stretched_json.valid
    classified_sold = nil
    self.listing_data_will_change!
    self.listing_data = self.stretched_json.try(:to_hash)
    save!
  end


  #
  # Checkers

  def check_statuses
    if not_found? != stretched_json.object.not_found?
      return @scrape_errors << { pt: "not_found: #{not_found}", page: "not_found: #{stretched_json.object.not_found?}" }
    end

    if is_valid? != stretched_json.object.valid
      @scrape_errors << { pt: "is_valid?: #{is_valid?}", page: "valid: #{stretched_json.object.valid}" }
    end
  end

  def check_listing_data
    listing_data.each do |attr, value|
      next if attr == "item_data"
      if value && irongrid_listing.nil?
        @scrape_errors << { pt: "#{attr}: #{value}", page: "#{attr}: nil listing" }
      elsif value != irongrid_listing[attr]
        next if %w(url digest image_download_attempted).include?(attr)
        @scrape_errors << { pt: "#{attr}: #{value}", page: "#{attr}: #{irongrid_listing[attr]}" }
      end
    end
  end

  def check_item_data
    return unless listing_data['item_data']
    listing_data['item_data'].each do |attr, value|
      if value && irongrid_listing.nil?
        @scrape_errors << { pt: "#{attr}: #{value}", page: "#{attr}: nil listing" }
      elsif ElasticSearchObject.is_object_in_index?(attr)
        check_es_object(attr, value)
      else
        check_value(attr, value)
      end
    end
  end

  def check_value(attr, pt_value)
    return if %w(description keywords image_download_attempted seller_domain).include?(attr)
    return if (irongrid_value = irongrid_listing['item_data'][attr]) == pt_value
    return if pt_value.is_a?(String) && irongrid_value.is_a?(String) && (pt_value.downcase == irongrid_value.downcase)
    @scrape_errors << { pt: "#{attr}: #{pt_value}", page: "#{attr}: #{irongrid_value}" }
  end

  def check_es_object(attr, pt_value)
    pt_value = es_object_to_hash(pt_value)
    irongrid_value = es_object_to_hash(irongrid_listing['item_data'][attr])

    pt_value.each do |k, v|
      next if (v == "default") && (irongrid_value[k] == "hard")
      unless irongrid_value[k] == v
        @scrape_errors << { pt: "#{attr}.#{k}: #{v}", page: "#{attr}.#{k}: #{irongrid_value[k]}" }
      end
    end
  end

  def es_object_to_hash(varray)
    varray ||= []
    varray.reduce({}) {|result, hashie| result.merge!(hashie.to_h)}
  end

  def print_errors
    return if scrape_errors.empty?
    title_hash = category1_hash = nil
    if listing_data.try(:[], 'item_data')
      title_hash = es_object_to_hash(listing_data['item_data']['title'])
      category1_hash = es_object_to_hash(listing_data['item_data']['category1'])
    end
    puts "##################################"
    puts "ParserTest #{id} has errors!"
    puts "  title:     #{title_hash["title"]}" if title_hash
    puts "  category1: #{category1_hash["category1"]} (#{category1_hash["classification_type"]})" if category1_hash
    puts "  url:       #{source_url}"

    puts "### Errors:"
    scrape_errors.each do |error|
      if error[:pt].is_a?(String)
        puts "  JSON: #{error[:pt][0..500]}"
      else
        puts "  JSON: #{error[:pt]}"
      end
      if error[:page].is_a?(String)
        puts "  Page: #{error[:page][0..500]}"
      else
        puts "  Page: #{error[:page]}"
      end
    end
  end

  def check_parser_test
    @scrape_errors = []
    fetch_page

    if @scraper[:error]
      @scrape_errors << { page: @scraper[:error] }
      print_errors
      return
    end

    check_statuses

    if listing_data.present? && stretched_json.object.valid?
      check_listing_data
      check_item_data
    end

    print_errors

  rescue Exception => e
    puts "ERROR for [#{id}]: #{e.message} #{e.backtrace}"
  end


  private

  def send_html_to_s3
    return unless should_send_to_s3

    @http ||= PageUtils::HTTP.new
    page = @http.fetch_page(url)

    s3 = AWS::S3.new(AWS_CREDENTIALS)
    s3_object = s3.buckets[bucket_name].objects["#{@scraper.seller_domain.gsub(".","-")}-#{Digest::MD5.hexdigest(source_url)}.html"]
    s3_object.write(page.body, { acl: :public_read })
    self[:html_on_s3] = s3_object.public_url.to_s
  end


  def bucket_name
    Rails.env.production? ? 'scoperrific-test-pages' : 'scoperrific-test-pages' + "-#{Rails.env}"
  end
end
