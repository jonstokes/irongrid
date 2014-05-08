# == Schema Information
#
# Table name: parser_tests
#
#  id                     :integer          not null, primary key
#  engine                 :string(255)
#  url                    :string(255)
#  digest                 :string(255)
#  title                  :text
#  description            :text
#  keywords               :text
#  listing_type           :string(255)
#  seller_domain          :string(255)
#  seller_name            :string(255)
#  category1              :string(255)
#  category2              :string(255)
#  item_condition         :string(255)
#  image                  :string(255)
#  stock_status           :string(255)
#  item_location          :string(255)
#  price_in_cents         :integer
#  price_on_request       :string(255)
#  sale_price_in_cents    :integer
#  buy_now_price_in_cents :integer
#  current_bid_in_cents   :integer
#  minimum_bid_in_cents   :integer
#  reserve_in_cents       :integer
#  auction_ends           :datetime
#  html_on_s3             :string(255)
#  listing_is_valid       :boolean
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  not_found              :boolean
#  item_sold              :boolean
#  caliber                :string(255)
#  number_of_rounds       :integer
#  grains                 :integer
#  manufacturer           :string(255)
#  model                  :string(255)
#

class ParserTest < ActiveRecord::Base
  include PageUtils
  include Retryable

  attr_accessible :source_url, :seller_domain, :is_valid, :not_found, :classified_sold, :html_on_s3, :should_send_to_s3
  attr_accessible :listing_data
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
