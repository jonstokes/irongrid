module SiteConversion
  #
  # New Stretched code
  #

  def to_yaml
    {
      'name'                   => name,
      'domain'                 => domain,
      'read_interval'          => read_interval,
      'timezone'               => timezone,
      'registrations'          => registrations,
      'affiliate_link_tag'     => affiliate_link_tag,
      'affiliate_program'      => affiliate_program,
      'product_session_format' => product_session_format,
      'sessions'               => sessions
    }.to_yaml
  end

  def write_yaml
    File.open("#{Rails.root}/spec/fixtures/sites/#{domain_dashed}.yml", "w") do |f|
      f.puts to_yaml
    end
  end

  def domain_dashed
    domain.gsub ".", "--"
  end

  def registrations
    if page_adapter
      page_adapter_registrations
    elsif feed_adapter
      feed_adapter_registrations
    end
  end

  def page_adapter_registrations
    @page_adapter_registrations ||= {
      'session_queue' => {
        "#{domain}" => {}
      },
      'object_adapter' => {
        "#{domain}/product_page" => {
          '$key'      => 'globals/product_page',
          'attribute' => object_attributes
        },
        "#{domain}/product_link" => {
          '$key'      => 'globals/product_link',
          'xpath'     => feed_product_link_xpath,
          'attribute' => {
            'product_link' => [
              { 'find_by_xpath' => { 'xpath' => './@href' } }
            ],
            'seller_domain' => [{ 'value' => domain }]
          }
        }
      }
    }
  end

  def feed_adapter_registrations
    @page_adapter_registrations ||= {
      'session_queue' => {
        "#{domain}" => {}
      },
      'object_adapter' => {
        "#{domain}/product_feed" => {
          '$key'      => 'globals/product_page',
          'xpath'     => feed_product_xpath,
          'attribute' => object_attributes
        }
      }
    }
  end

  def product_session_format
    return {} unless page_adapter
    {
      'queue' => domain,
      'session_definition' => session_def(adapter_format),
      'object_adapters' => [ "#{domain}/product_page" ]
    }
  end

  def sessions
    @sessions ||= begin
      session_list = []
      url_list = []
      urls.each do |url|
        if url_count(url_list) >= 300
          session_list << session_hash(url_list)
          url_list = []
        else
          url_list << url
        end
      end
      session_list << session_hash(url_list)
      session_list
    end
  end

  def url_count(url_list)
    count = 0
    url_list.each do |url|
      if url['start_at_page']
        count += url['stop_at_page']
      else
        count += 1
      end
    end
    count
  end

  def session_hash(url_list)
    {
      'queue' => domain,
      'session_definition' => session_def(feed_format),
      'object_adapters' => adapters_for_sessions,
      'urls' => url_list
    }
  end

  def feed_product_link_xpath
    return feeds.first.product_link_xpath.sub("/@href", "") if feeds.any?
    return link_sources['seed_links'].first.last['link_xpaths'].first.sub("/@href", "") if link_sources['seed_links']
    return link_sources['compressed_links'].first.last['link_xpaths'].first.sub("/@href", "")
  end

  def feed_product_xpath
    return feeds.first.product_xpath if feeds.any?
  end

  def urls
    if feeds.any?
      link_sources['feeds'].map { |feed| convert_feed(feed) }
    else
      convert_legacy_feeds
    end
  end

  def convert_legacy_feeds
    convert_seed_links + convert_compressed_links
  end

  def convert_seed_links
    return [] unless link_sources['seed_links']
    link_sources['seed_links'].map do |seed|
      { 'url' => seed.first.to_s }
    end
  end

  def convert_compressed_links
    return [] unless link_sources['compressed_links']
    link_sources['compressed_links'].map do |clink|
      hash = {
        'url' => clink.first.to_s,
        'start_at_page' => clink.last['start_at_page'],
        'stop_at_page' => clink.last['stop_at_page'],
      }
      hash.merge!('step' => clink.last['step']) if clink.last['step']
      hash
    end
  end

  def feed_format
    return feeds.first.format if feeds.any?
  end

  def convert_feed(feed)
    return { 'url' => feed['url'] } unless !!feed['url']['start_at_page']
    hash = {
      'url'           => feed['url'],
      'start_at_page' => feed['start_at_page'],
      'stop_at_page'  => feed['stop_at_page']
    }
    hash.merge!('step' => feed['step']) if feed['step']
    hash
  end

  def adapters_for_sessions
    return ["#{domain}/product_link"] if page_adapter
    ["#{domain}/product_feed"]
  end

  def adapter
    @site_data[:page_adapter] || @site_data[:feed_adapter]
  end

  def adapter_format
    adapter['format']
  end

  def session_def(format)
    case format.to_s
    when 'dhtml'
      'globals/standard_dhtml_session'
    when 'xml'
      'globals/standard_xml_session'
    else
      'globals/standard_html_session'
    end
  end

  def object_attributes
    @object_attributes ||= begin
      obj_attrs = {}
      adapter.each do |attribute, setters|
        next if %w(seller_defaults validation digest_attributes).include?(attribute)
        new_setters = setters.map do |setter|
          convert_setter(setter)
        end
        new_setters << { 'value' => default_for(attribute) } if default_for(attribute)
        obj_attrs.merge!(convert_attribute(attribute) => new_setters)
      end
      obj_attrs
    end
  end

  def default_for(attribute)
    return unless adapter['seller_defaults']
    return unless val = adapter['seller_defaults'][attribute]
    convert_value(val)
  end

  def convert_value(val)
    return "RetailListing" if val.downcase == "retail"
    return "AuctionListing" if val.downcase == "auction"
    return "ClassifiedListing" if val.downcase == "classified"
    return "in_stock" if val.downcase == "in stock"
    return "out_of_stock" if val.downcase == "out of stock"
    val
  end

  def convert_attribute(attribute)
    return "availability" if attribute == "stock_status"
    return attribute.sub("listing_", "") if attribute[/listing_/]
    return attribute.sub("item_", "") if attribute[/item_/]
    return "#{attribute}_in_cents" if %w(price sale_price buy_now_price current_bid minimum_bid starting_bid reserve).include?(attribute)
    return "product_#{attribute}" if %w(number_of_rounds grains manufacturer category1 caliber caliber_category upc sku mpn).include?(attribute)
    attribute
  end

  def convert_setter(setter)
    return setter['scraper_method'] unless setter['arguments']
    hash = { convert_method(setter['scraper_method']) => convert_args(setter['arguments']) }
    hash.merge!('filters' => setter['arguments']['filters']) if setter['arguments']['filters']
    hash
  end

  def convert_method(method)
    return method.sub("classify_by", "label_by") if method[/classify_by/]
    return method
  end

  def convert_args(arguments)
    return unless arguments
    args = arguments.reject { |k, v| k == 'filters' }
    mappings = { 'xpath' => 'xpath', 'regexp' => 'pattern', 'type' => 'label', 'attribute' => 'attribute', 'value' => 'value' }
    hash = Hash[args.map { |k, v| [(mappings[k] || k), v] }]
    hash['label'] = convert_value(hash['label']) if hash['label']
    hash
  end

end
