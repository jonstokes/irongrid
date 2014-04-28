class ListingCleaner < CoreModel
  attr_reader :raw_listing, :site, :url, :scrubbed, :normalized, :es_objects, :metadata, :keywords, :description

  # Rails complains about circular dependencies if I don't do this
  ITEM_DATA_ATTRIBUTES = Listing::ITEM_DATA_ATTRIBUTES
  ES_OBJECTS = Listing::ES_OBJECTS

  DEFAULT_DIGEST_ATTRIBUTES = %w(
    title
    image_source
    description
    keywords
    type
    seller_domain
    item_condition
    item_location
    category1
    caliber_category
    caliber
    manufacturer
    grains
    number_of_rounds
    current_price_in_cents
  )

  ES_OBJECTS.each do |key|
    define_method key do
      es_objects[key.to_sym].try(:[], key)
    end
  end

  def initialize(opts)
    @raw_listing, @site, @url = opts[:raw_listing], opts[:site], opts[:url]
    @keywords = raw_listing['keywords']
    @description = raw_listing['description']

    @es_objects = {}
    es_objects[:title] = {
     "title" => raw_listing['title'],
     "autocomplete" => raw_listing['title']
    }
    es_objects[:category1] = hard_categorize("category1") ||
      default_categorize("category1") ||
      {"category1" => "None", "classification_type" => "fall_through"}

    return unless is_valid?

    @scrubbed = {}
    @normalized = {}
    @metadata = MetadataTable.new

    extract_metadata

    es_objects[:title].merge!(
      "scrubbed" => scrubbed[:title],
      "normalized" => normalized[:title]
    )

    if es_objects[:category1]["classification_type"] == "fall_through"
      es_objects[:category1] = metadata_categorize ||
        soft_categorize("category1") ||
        {"category1" => "None", "classification_type" => "fall_through"}
    end
  end

  def to_h
    @listing ||= {
      "url"          => url,
      "digest"       => digest,
      "type"         => type,
      "item_data"    => item_data
    }
  end

  def item_data
    @item_data ||= begin
      data = {}
      ES_OBJECTS.each do |attr|
        data.merge!(attr => json(es_objects[attr.to_sym]))
      end
      ITEM_DATA_ATTRIBUTES.each do |attr|
        data.merge!(attr => send(attr)) unless attr == "image"
      end
      data
    end
  end

  def json(es_object)
    return unless es_object
    es_object.map do |k, v|
      val = v.is_a?(String) && !(v == "fall_through") ? v.gsub("_", " ") : v
      { k => val }
    end.compact
  end

  def digest
    digest_string = ""
    @site.digest_attributes(default_digest_attributes).each do |attr|
      if ES_OBJECTS.include?(attr)
        digest_string << "#{es_objects[attr.to_sym]}"
      elsif send(attr)
        digest_string << "#{send(attr)}"
      end
    end
    Digest::MD5.hexdigest(digest_string)
  end

  def seller_domain
    #This is needed for some digest calculations
    site.domain
  end

  def seller_name
    #This is used in the Parser Tests
    site.name
  end

  def affiliate_link_tag
    site.affiliate_link_tag
  end

  def price_per_round_in_cents
    return nil unless current_price_in_cents && number_of_rounds
    (current_price_in_cents.to_f / number_of_rounds.to_f).round
  rescue
    Rails.logger.info "Price per round failed for #{url} with title #{title}"
    0
  end

  def description
    @description ||= raw_listing['description']
  end

  def availability
    stock_status.parameterize("_")
  end

  def image_source
    return nil unless @raw_listing['image']
    return unless image_source = clean_up_image_url(@raw_listing['image'])
    unless is_valid_image_url?(image_source)
      notify "## IMAGE ERROR at #{url}. Image source is #{image_source}"
      return nil
    end
    image_source
  end

  def image_download_attempted
    false
  end

  def item_condition
    if ['New', 'Used'].include? raw_listing['item_condition']
      return raw_listing['item_condition']
    elsif raw_listing['condition_new']
      return "New"
    elsif raw_listing['condition_used']
      return "Used"
    else
      site.default_condition.try(:titleize) || "Unknown"
    end
  end

  def item_location
    @item_location ||= begin
      loc = raw_listing['item_location']
      loc && !loc.blank? ? loc : site.default_item_location
    end
  end

  #
  # Extended item data
  #

  def extract_metadata
    if %w(Ammunition Accessories None).include? category1
      extract_ammo
    elsif category1 == "Guns"
      extract_guns
    elsif category1 == "Optics"
      extract_optics
    end
  end

  def extract_ammo
    ammo_metadata = [:caliber, :manufacturer, :grains, :number_of_rounds, :caliber_category]
    scrubbed[:title] = ProductDetails::Scrubber.scrub_all(title)
    extract_metadata_from_field(:title, [:caliber, :grains, :number_of_rounds, :manufacturer])
    normalized[:title] = ProductDetails::renormalize_all(normalized[:title])

    if keywords
      scrubbed[:keywords] = ProductDetails::Scrubber.scrub_all(keywords)
      extract_metadata_from_field(:keywords, [:caliber, :grains, :number_of_rounds, :manufacturer])
    end

    extract_metadata_from_raw_listing(*ammo_metadata)

    ammo_metadata.each { |attr| update_es_object(attr) }
  end

  def extract_guns
    gun_metadata = [:caliber, :manufacturer, :caliber_category]
    scrubbed[:title] = ProductDetails::Scrubber.scrub_all(title)
    extract_metadata_from_field(:title, [:caliber, :manufacturer])
    normalized[:title] = ProductDetails.renormalize_all(normalized[:title])

    if keywords
      scrubbed[:keywords] = ProductDetails::Scrubber.scrub_all(keywords)
      extract_metadata_from_field(:keywords, [:caliber, :manufacturer])
    end

    extract_metadata_from_raw_listing(*gun_metadata)

    gun_metadata.each { |attr| update_es_object(attr) }
  end

  def extract_optics
    scrubbed[:title] = ProductDetails::Scrubber.scrub(title, :inches, :punctuation, :color)
    extract_metadata_from_field(:title, [:manufacturer])

    if keywords
      scrubbed[:keywords] = ProductDetails::Scrubber.scrub(keywords, :inches, :punctuation, :color)
      extract_metadata_from_field(:keywords, [:manufacturer])
    end

    extract_metadata_from_raw_listing(:manufacturer)

    update_es_object(:manufacturer)
  end

  def update_es_object(attr)
    es_objects[attr] ||= {}
    es_objects[attr].merge!(
      attr.to_s => metadata.final_value(attr),
      "classification_type" => metadata.classification_type(attr)
    )
  end

  def extract_metadata_from_field(field_name, attributes)
    if attributes.include?(:caliber)
      normalized[field_name] = ProductDetails::Caliber.analyze(scrubbed[field_name])
      results = ProductDetails::Caliber.parse(normalized[field_name])
      normalized[field_name] = results[:text]
      metadata.update(attribute: :caliber, source: field_name, content: results[:keywords].first)
      metadata.update(attribute: :caliber_category, source: field_name, content: results[:category])
    end

    if attributes.include?(:manufacturer)
      normalized[field_name] = ProductDetails::Manufacturer.analyze(normalized[field_name] || scrubbed[field_name])
      results = ProductDetails::Manufacturer.parse(normalized[field_name])
      normalized[field_name] = results[:text]
      metadata.update(attribute: :manufacturer, source: field_name, content: results[:keywords].first)
    end

    if attributes.include?(:grains)
      results = ProductDetails::Grains.parse(normalized[field_name])
      normalized[field_name] = results[:text]
      metadata.update(attribute: :grains, source: field_name, content: results[:keywords].first)
    end

    if attributes.include?(:number_of_rounds)
      results = ProductDetails::Rounds.parse(normalized[field_name])
      normalized[field_name] = results[:text]
      metadata.update(attribute: :number_of_rounds, source: field_name, content: results[:keywords].first)
    end
  end

  def extract_metadata_from_raw_listing(*attributes)
    if attributes.include?(:caliber) && raw_listing['caliber']
      str = ProductDetails::Scrubber.scrub(raw_listing['caliber'], :punctuation, :caliber)
      str = ProductDetails::Caliber.analyze(str)
      results = ProductDetails::Caliber.parse(str)
      metadata.update(attribute: :caliber, source: :raw, content: results[:keywords].first)
      metadata.update(attribute: :caliber_category, source: :raw, content: results[:category])
    end

    if attributes.include?(:caliber_category) && raw_listing['caliber_category']
      str = ProductDetails::Scrubber.scrub(raw_listing['caliber_category'], :punctuation, :caliber)
      str = ProductDetails::Caliber.analyze(str)
      results = ProductDetails::Caliber.parse_category(str)
      metadata.update(attribute: :caliber_category, source: :raw, content: results[:keywords].first)
    end

    if attributes.include?(:manufacturer) && raw_listing['manufacturer']
      str = ProductDetails::Scrubber.scrub(raw_listing['manufacturer'], :punctuation)
      str = ProductDetails::Manufacturer.analyze(str)
      results = ProductDetails::Manufacturer.parse(str)
      metadata.update(attribute: :manufacturer, source: :raw, content: results[:keywords].first)
    end

    if attributes.include?(:grains) && raw_listing['grains']
      metadata.update(attribute: :grains, source: :raw, content: raw_listing['grains'].delete(",").to_i)
    end

    if attributes.include?(:number_of_rounds) && raw_listing['number_of_rounds']
      metadata.update(attribute: :number_of_rounds, source: :raw, content: raw_listing['number_of_rounds'].delete(",").to_i)
    end
  end

  def hard_categorize(cat)
    return unless value = raw_listing[cat]
    { cat => value, "classification_type" => "hard" }
  end

  def metadata_categorize
    return unless grains && number_of_rounds && caliber
    {"category1" => "Ammunition", "classification_type" => "metadata"}
  end

  def default_categorize(cat)
    return unless value = site.send("default_#{cat}")
    { cat => value, "classification_type" => "default" }
  end

  def soft_categorize(cat)
    return unless scrubbed[:title]
    SoftCategorizer.new(
      category_name: cat,
      price: current_price_in_cents,
      title: scrubbed[:title]
    ).categorize
  end

  #
  # Override
  #

  def default_digest_attributes
    # override
  end


  def stock_status
    # override
  end


  def current_price_in_cents
    # override
  end

  def is_valid?
    # override
  end

  def type
    # override
  end

  def method_missing(method_id, *arguments, &block)
    return nil if ITEM_DATA_ATTRIBUTES.include?(method_id.to_s)
    super
  end

  # private

  def is_valid_image_url?(link)
    return false unless is_valid_url?(link)
    extensions = %w(.png .jpg .jpeg .gif .bmp)
    extensions.select { |ext| link.downcase[ext] }.any?
  end

  def is_valid_url?(link)
    begin
      uri = URI.parse(link)
      %w( http https ).include?(uri.scheme)
    rescue URI::BadURIError
      return false
    rescue URI::InvalidURIError
      return false
    end
  end

  def validation_string
    validation_type = type.split("Listing").first.downcase
    site.validation[validation_type].gsub("raw", "raw_listing").gsub("clean", "listing")
  end

  #
  # Listing clean-up methods
  #

  def clean_up_image_url(link)
    return unless retval = URI.encode(link)
    retval = "#{site.image_prefix}#{retval}" if !is_valid_url?(retval) && site.image_prefix
    return retval unless retval["?"]
    retval.split("?").first
  end

  def convert_time(time)
    return unless time
    Time.zone = site.seller_default_timezone ? site.seller_default_timezone : DEFAULT_LISTING_TIMEZONE
    begin
      Time.zone.parse(time).utc || Time.strptime(time, "%m/%d/%Y %H:%M:%S").utc
    rescue ArgumentError
      Time.strptime(time, "%m/%d/%Y %H:%M:%S").utc
    end
  end

  def convert_price(price)
    return nil unless price

    # All prices are in cents
    stripped_price = price.strip.gsub(" ", "").sub("$","").sub(",","")
    if stripped_price[/\.\d\d\.\D*\z/]
      stripped_price.gsub(".","").to_i
    elsif stripped_price[/\.\d\.\D*\z/]
      stripped_price.gsub(".","").to_i
    elsif stripped_price[/\.\D*\z/]
      stripped_price.sub(".","").to_i * 100
    elsif stripped_price[/\.\d\D*\z/]
      stripped_price.sub(".","").to_i * 10
    elsif stripped_price[/\.\d\d\D*\z/]
      stripped_price.sub(".","").to_i
    else
      stripped_price.sub(".","").to_i * 100
    end
  end
end
