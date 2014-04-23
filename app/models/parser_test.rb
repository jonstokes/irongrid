class ParserTest < ActiveRecord::Base
  include PageUtils
  include Retryable

  attr_accessible :source_url, :seller_domain, :is_valid, :not_found, :classified_sold, :html_on_s3, :should_send_to_s3
  attr_accessible :listing_data
  serialize :listing_data, JSON
  attr_reader :scraper

  before_save :send_html_to_s3

  LISTING_DATA_ATTRIBUTES = Listing::ES_OBJECTS + Listing::ITEM_DATA_ATTRIBUTES

  Listing::ES_OBJECTS.each do |key|
    define_method key do
      listing_data['item_data'][key].detect { |attr| attr[key] }.try(:[], key) if listing_data
    end
  end

  Listing::ITEM_DATA_ATTRIBUTES.each do |key|
    next if %w(seller_domain type).include?(key)
    define_method key do
      listing_data['item_data'][key] if listing_data
    end
  end

  %w(url digest).each do |key|
    define_method key do
      listing_data[key] if listing_data
    end
  end

  def listing_type
    listing_data['type'] if listing_data
  end

  def fetch_page
    domain = seller_domain || URI(url).host
    @scraper = PageUtils::Test.scrape_page(url: source_location, domain: domain)
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
