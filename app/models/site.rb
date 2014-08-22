class Site < CoreModel
  include Github
  include IrongridRedisPool

  attr_accessor :site_data, :pool

  SITE_ATTRIBUTES = [
    :name,
    :domain,
    :read_interval,
    :timezone,
    :created_at,
    :updated_at,
    :read_at,
    :size,
    :active,
    :commit_sha,
    :stats,
    :affiliate_link_tag,
    :affiliate_program,
    :page_adapter,
    :feed_adapter,
    :read_with,
    :link_sources,
    :rate_limits
  ]

  SITE_ATTRIBUTES.each do |key|
    define_method key do
      if key.to_s[/\_adapter/]
        var = eval("@#{key}")
        var ||= Adapter.new(@site_data[key]) if @site_data[key]
      else
        @site_data[key]
      end
    end
  end

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
      'product_session_format' => product_session_format,
      'sessions'               => sessions
    }.to_yaml
  end

  def self.write_all
    domains = YAML.load_file("#{Rails.root}/spec/fixtures/sites/manifest.yml")
    domains.each do |domain|
      puts "Writing file for #{domain}..."
      next unless site = Site.new(domain: domain, source: :local) rescue nil
      site.write_yaml
    end
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
      adapter.map do |attribute, setters|
        next if %w(seller_defaults validation digest_attributes).include?(attribute)
        new_setters = setters.map do |setter|
          convert_setter(setter)
        end
        new_setters << { 'value' => default_for(attribute) } if default_for(attribute)
        { convert_attribute(attribute) => new_setters }
      end.compact
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
    return "product_#{attribute}" if %w(numer_of_rounds grains manufacturer category1 caliber caliber_category upc sku mpn).include?(attribute)
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

  #
  # Old site code
  #

  def initialize(opts)
    raise "Domain required!" unless opts[:domain]
    @site_data = { domain: opts[:domain] }
    @pool = opts[:pool].try(:to_sym) || :irongrid
    load_data!(opts[:source].try(:to_sym))
  end

  def update(attrs)
    check_attributes(attrs)
    load_data!
    @site_data.merge!(attrs)
    write_to_redis
  end

  def redis_pool
    pool == :validator ? VALIDATOR_REDIS_POOL : IRONGRID_REDIS_POOL
  end

  def update_stats(attrs)
    load_data!
    @site_data[:stats] ||= {}
    attrs.merge!(updated_at: Time.now)
    @site_data[:stats].merge!(attrs)
    write_to_redis
  end

  def rate_limit
    return 5 unless self.rate_limits
    myzone = "America/Chicago"
    Time.zone = myzone
    self.rate_limits.each do |time_slot, attr|
      start_time = Time.zone.parse(attr["start"])
      duration = attr["duration"].to_i.hours
      end_time = (start_time + duration).in_time_zone(myzone)
      return attr["rate"] if (start_time..end_time).cover?(Time.zone.now)
    end
    return self.rate_limits["peak"]["rate"]
  end

  def mark_read!
    update(read_at: Time.now.utc)
  end

  def should_read?
    return true unless read_at && read_interval
    Time.now.utc > read_at + read_interval
  end

  def refresh_only?
    !!self.link_sources["refresh_only"]
  end

  def exists?
    page_adapter || feed_adapter
  end

  def feeds
    return [] unless link_sources['feeds']
    @feeds ||= link_sources['feeds'].map do |feed|
      if feed['start_at_page']
        expand_links(feed.symbolize_keys)
      else
        feed.symbolize_keys
      end
    end.flatten.uniq.map { |f| Feed.new(f) }
  end

  def expand_links(feed)
    interval = feed[:step] || 1
    (feed[:start_at_page]..feed[:stop_at_page]).step(interval).map do |page_number|
      feed.merge(url: feed[:url].sub("PAGENUM", page_number.to_s))
    end
  end

  def write_to_redis
    redis_pool.with do |conn|
      conn.set("site--#{domain}", @site_data.to_yaml)
      conn.sadd("site--index", domain)
    end
  end

  def self.domains
    with_redis { |conn| conn.smembers "site--index" }
  end

  def self.add_domains(list)
    with_redis do |conn|
      list.each do |domain|
        if conn.sadd("site--index", domain)
          create_site_from_local(domain)
        end
      end
    end
  end

  def self.remove_domain(domain)
    with_redis do |conn|
      conn.srem("site--index", domain)
    end
  end

  def self.create_site_from_local(domain)
    puts "Creating site #{domain} in redis from local repo..."
    Site.new(domain: domain, source: :local).send(:write_to_redis)
  end

  def self.update_site_from_local(site)
    local_site = Site.new(domain: site.domain, source: :local)
    puts "Updating #{site.domain}..."
    Site::SITE_ATTRIBUTES.each do |attr|
      next if [:read_at, :stats].include?(attr)
      site.site_data[attr] = local_site.site_data[attr]
    end
    site.send(:write_to_redis)
  end

  def self.all
    domains.map do |domain|
      Site.new(domain: domain)
    end.compact
  end

  private

  def load_data!(source=nil)
    case source
    when :local
      load_from_local
    when :git
      load_from_github
    when :fixture
      load_from_fixture
    when :form
      write_to_redis if pool == :validator
    else
      load_from_redis
    end
  end

  def check_attributes(obj)
    if obj.is_a?(Hash)
      obj.keys.each { |attr| raise "Invalid attribute #{attr}" unless SITE_ATTRIBUTES.include?(attr) }
    else
      attr = obj.to_sym
      raise "Invalid attribute #{attr}" unless SITE_ATTRIBUTES.include?(attr)
    end
  end

  def load_from_redis
    @site_data = redis_pool.with do |conn|
      YAML.load(conn.get("site--#{domain}"))
    end.symbolize_keys
  rescue TypeError
    raise "Site #{domain} does not exist!"
  end

  def load_from_local
    branch = Figaro.env.site_branch rescue "master"
    site_dir = domain.gsub(".","--")
    directory = "#{Figaro.env.sites_repo}/sites/#{site_dir}"

    @site_data[:page_adapter] = YAML.load_file("#{directory}/page_adapter.yml") if File.exists?("#{directory}/page_adapter.yml")
    @site_data[:feed_adapter] = YAML.load_file("#{directory}/feed_adapter.yml") if File.exists?("#{directory}/feed_adapter.yml")
    @site_data[:link_sources] = YAML.load_file("#{directory}/link_sources.yml")
    @site_data[:rate_limits]  = YAML.load_file("#{directory}/rate_limits.yml")
    YAML.load_file("#{directory}/attributes.yml").each do |k, v|
      @site_data[k.to_sym] = v
    end
  end

  def load_from_fixture
    filename = domain.gsub(".","--") + ".yml"
    @site_data = YAML.load_file("#{Rails.root}/spec/fixtures/sites/#{filename}")['site_data'].symbolize_keys
  end

  def load_from_github
    site_dir = domain.gsub(".","--")
    page_adapter_source = fetch_file_from_github("sites/#{site_dir}/page_adapter.yml")
    feed_adapter_source = fetch_file_from_github("sites/#{site_dir}/feed_adapter.yml")
    @site_data[:page_adapter] = YAML.load(page_adapter_source) if page_adapter_source
    @site_data[:feed_adapter] = YAML.load(feed_adapter_source) if feed_adapter_source
    @site_data[:link_sources] = YAML.load(fetch_file_from_github("sites/#{site_dir}/link_sources.yml"))
    @site_data[:rate_limits]  = YAML.load(fetch_file_from_github("sites/#{site_dir}/rate_limits.yml"))
    YAML.load(fetch_file_from_github("sites/#{site_dir}/attributes.yml")).each do |k, v|
      @site_data[k.to_sym] = v
    end
  end
end
