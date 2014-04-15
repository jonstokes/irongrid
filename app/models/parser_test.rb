class ParserTest < ActiveRecord::Base
  include PageUtils

  attr_accessible :should_send_to_s3, :listing_is_valid, :reserve_in_cents, :auction_ends, :buy_now_price_in_cents,
    :category1, :category2, :current_bid_in_cents, :description, :digest, :engine, :html_on_s3, :image, :item_condition,
    :item_location, :keywords, :listing_type, :minimum_bid_in_cents, :price_in_cents, :price_on_request, :sale_price_in_cents,
    :seller_domain, :seller_name, :stock_status, :title, :url, :not_found, :item_sold,
    :manufacturer, :grains, :number_of_rounds, :model, :caliber
  attr_reader :page

  def should_send_to_s3
    @should_send_to_s3 == "1"
  end

  def should_send_to_s3=(value)
    @should_send_to_s3 = value
  end

  def send_html_to_s3
    return unless should_send_to_s3
    s3 = AWS::S3.new(AWS_CREDENTIALS)
    html = get_page(url).body
    base_name = 'scoperrific-test-pages'
    bucket_name = Rails.env.production? ? base_name : base_name + "-#{Rails.env}"
    s3_object = s3.buckets[bucket_name].objects["#{@page.listing["seller_domain"].gsub(".","-")}-#{@page.listing["title"].gsub(" ","_")}.html"]
    s3_object.write(html, :acl => :public_read) unless s3_object.exists?
    self[:html_on_s3] = s3_object.public_url.to_s
  end

  def listing_should_show_correct_attributes
    fetch_page
    field_list.each do |field|
      if error_condition(field)
        errors.add field, error_for_field(field)
      end
    end

    page_attributes.each do |attr|
      errors.add attr, "Scraper: #{@page.listing[attr]} Form: #{self.send(attr.to_sym)}" unless self.send(attr.to_sym).nil? || self.send(attr.to_sym).empty? || (@page.listing[attr] == self.send(attr.to_sym))
    end

    price_attributes.each do |attr|
      attr_in_cents = "#{attr}_in_cents"
      errors.add attr_in_cents, "Scraper: #{@page.listing[attr_in_cents]} [#{@page.raw_listing[attr]}] Form: #{self.send(attr_in_cents)}" unless self.send(attr_in_cents).nil? || (@page.listing[attr_in_cents] == self.send(attr_in_cents))
    end
    errors
  end

  def print_extended_item_data
    fetch_page
    puts "#### #{self.id} ################"
    puts "Title: #{@page.listing["title"]}"
    puts "Category: #{@page.listing["category_data"]["category1"]}" if @page.listing["category_data"]
    puts "Manufacturer: #{@page.listing["extended_item_data"]["manufacturer"]}" if @page.listing["extended_item_data"]["manufacturer"]
    puts "Caliber: #{@page.listing["extended_item_data"]["caliber"]}" if @page.listing["extended_item_data"]["caliber"]
    puts "Num rounds: #{@page.listing["extended_item_data"]["number_of_rounds"]}" if @page.listing["extended_item_data"]["number_of_rounds"]
    puts "Grains: #{@page.listing["extended_item_data"]["grains"]}" if @page.listing["extended_item_data"]["grains"]
    puts ""
  end

  def fetch_page
    domain = URI(url).host
    site = Site.new(domain: domain, source: :local)
    source_location = html_on_s3 && !html_on_s3.blank? ? html_on_s3 : url
    source = get_page(source_location)
    @page = ListingScraper.new(site)
    @page.parse(doc: source.doc, url: url)
  end

  def field_list
    @field_list ||= [
      :listing_is_valid,
      :not_found,
      :item_sold,
      :title,
      :category1,
      :category2,
      :description,
      :keywords,
      :item_condition,
      :stock_status,
      :item_location,
      :auction_ends,
      :listing_type,
      :manufacturer,
      :caliber,
      :number_of_rounds,
      :grains,
      :model
    ]
  end

  def page_attributes
    @page_attributes ||= %w( engine digest seller_domain seller_name image price_on_request )
  end

  def price_attributes
    @price_attributes ||= %w( price sale_price buy_now_price current_bid minimum_bid reserve )
  end

  def error_for_field(field)
    case field
    when :description
      "Clean: #{@page.listing["description"]} Form: #{description}"
    when :keywords
      "Clean: #{@page.listing["keywords"]} Form: #{keywords}"
    when :listing_is_valid
      "Clean: #{@page.is_valid?} Form: #{listing_is_valid}"
    when :not_found
      "Clean: #{@page.not_found?} [Raw: #{@page.raw_listing["not_found"]}] Form: #{not_found}"
    when :item_sold
      "Clean: #{@page.classified_sold?} [Raw: #{@page.raw_listing["item_sold"]}] Form: #{item_sold}"
    when :title
      "Clean: #{@page.listing["title"] || "nil"} [Raw: #{@page.raw_listing["title"]}] Form: #{title}"
    when :listing_type
      "Clean: #{@page.type.chomp("Listing") || "nil"} Form: #{listing_type}"
    when :category1
      "Clean: #{@page.listing["category_data"]["category1"] || "nil"} [Raw: #{@page.raw_listing["category1"]}] Form: #{category1}"
    when :category2
      "Clean: #{@page.listing["category_data"]["category2"] || "nil"} [Raw: #{@page.raw_listing["category2"]}] Form: #{category2}"
    when :item_condition
      "Clean: #{@page.listing["item_condition"] || "nil"} [condition_new: #{@page.raw_listing["condition_new"]} | condition_used: #{@page.raw_listing["condition_used"]}] Form: #{item_condition}"
    when :stock_status
      "Clean: #{@page.listing["stock_status"] || "nil"} [in_stock_msg: #{@page.raw_listing["in_stock_message"]} | Out: #{@page.raw_listing["out_of_stock_message"]}] Form: #{stock_status}"
    when :item_location
      "Clean: #{@page.listing["item_location"] || "nil"} [Raw: #{@page.raw_listing["item_location"]}] Form: #{item_location}"
    when :auction_ends
      "Clean: #{@page.listing["auction_ends"] || "nil"} [Raw: #{@page.raw_listing["auction_ends"]}] Form: #{auction_ends}"
    when :manufacturer
      "Clean: #{@page.listing["extended_item_data"]["manufacturer"] || "nil"} [Raw: #{@page.raw_listing["manufacturer"]}] Form: #{manufacturer}"
    when :caliber
      "Clean: #{@page.listing["extended_item_data"]["caliber"] || "nil"} [Raw: #{@page.raw_listing["caliber"]}] Form: #{caliber}"
    when :grains
      "Clean: #{@page.listing["extended_item_data"]["grains"] || "nil"} [Raw: #{@page.raw_listing["grains"]}] Form: #{grains}"
    when :number_of_rounds
      "Clean: #{@page.listing["extended_item_data"]["number_of_rounds"] || "nil"} [Raw: #{@page.raw_listing["number_of_rounds"]}] Form: #{number_of_rounds}"
    when :model
      "Clean: #{@page.listing["extended_item_data"]["model"] || "nil"} [Raw: #{@page.raw_listing["model"]}] Form: #{model}"
    end
  end

  def error_condition(field)
    case field
    when :description
      description && !description.empty? && (@page.listing["description"].nil? || @page.listing["description"][description].nil?)
    when :keywords
      keywords && !keywords.empty? && (@page.listing["keywords"].nil? || @page.listing["keywords"][keywords].nil?)
    when :listing_is_valid
      listing_is_valid != !!@page.is_valid?
    when :not_found
      !!not_found != @page.not_found?
    when :item_sold
      !!item_sold != @page.classified_sold?
    when :title
      title && !title.empty? && (@page.listing["title"] != title)
    when :listing_type
      listing_type && !listing_type.empty? && (@page.type.chomp("Listing") != listing_type)
    when :category1
      category1 && !category1.empty? && (@page.listing["category_data"]["category1"] != category1)
    when :category2
      category2 && !category2.empty? && (@page.listing["category_data"]["category2"] != category2)
    when :item_condition
      item_condition && !item_condition.empty? && (@page.listing["item_condition"] != item_condition)
    when :stock_status
      stock_status && !stock_status.empty? && (@page.listing["stock_status"] != stock_status)
    when :item_location
      item_location && !item_location.empty? && (@page.listing["item_location"] != item_location)
    when :manufacturer
      !manufacturer.try(:empty?) && (@page.listing["extended_item_data"]["manufacturer"] != manufacturer)
    when :caliber
      !caliber.try(:empty?) && (@page.listing["extended_item_data"]["caliber"] != caliber)
    when :grains
      grains && (@page.listing["extended_item_data"]["grains"] != grains)
    when :number_of_rounds
      number_of_rounds && (@page.listing["extended_item_data"]["number_of_rounds"] != number_of_rounds)
    when :model
      !model.try(:empty?) && (@page.listing["extended_item_data"]["model"] != model)
    when :auction_ends
      if @page.listing["auction_ends"]
        end_range = ((@page.listing["auction_ends"] - 1.minute)..(@page.listing["auction_ends"] + 1.minute))
        Rails.logger.info "### Auction ending range is #{end_range}. Auction ends #{auction_ends}."
        auction_ends && (auction_ends.strftime("%Y") != "2008") && !(end_range.cover?(auction_ends))
      else
        false
      end
    end
  end

  def convert_auction_ends_to_utc
    auction_ends = auction_ends.utc if auction_ends
  end

  def should_show_error?(errors, field_name)
    !format_errors(errors, field_name).empty?
  end

  def format_errors(errors, field_name)
    output = ""
    errors.each do |field, error|
      if field == field_name
        output = error
      end
    end
    output
  end

  def format_all_errors(errors)
    output = ""
    errors.each do |field, error|
      output << "#{field}: #{error}"
      output << '\n'
    end
    output
  end

end

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
#


