class Site < LegacySite
  include Github
  include IrongridRedisPool

  attr_accessor :site_data, :pool

  SITE_ATTRIBUTES = [
    :name,
    :domain,
    :read_interval,
    :full_feed,
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
    :digest_attributes,
    :registrations,
    :sessions,
    :product_session_format
  ]

  SITE_ATTRIBUTES.each do |key|
    define_method key do
      @site_data[key]
    end
  end

  def initialize(opts)
    raise "Domain required!" unless opts[:domain]
    @site_data = { domain: opts[:domain] }
    @pool = opts[:pool].try(:to_sym) || :irongrid
    load_data!(opts[:source].try(:to_sym))
  end

  def write_yaml
    File.open("#{Figaro.env.sites_repo}/sites/#{domain_dashed}.yml", "w") do |f|
      f.puts @site_data.stringify_keys.to_yaml
    end
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

  def domain_dash
    domain.gsub(".","--")
  end

  def register
    Stretched::Registration.register_from_source(registrations)
  end

  def session_queue
    @session_queue ||= Stretched::SessionQueue.find_or_create(domain)
  end

  def listings_queue
    @listings_queue ||= Stretched::ObjectQueue.find_or_create("#{domain}/listings")
  end

  def product_links_queue
    @product_links_queue ||= Stretched::ObjectQueue.find_or_create("#{domain}/product_links")
  end

  def link_message_queue
    @lmq ||= LinkMessageQueue.new(domain: domain)
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

  def self.each
    domains.each do |domain|
      yield Site.new(domain: domain)
    end
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
      conn.del "site--#{domain}"
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
    site.register
  end

  def self.all
    domains.map do |domain|
      Site.new(domain: domain)
    end.compact
  end

  def self.full_product_feed_sites
    all.map do |site|
      site if site.full_feed
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
    filename = "#{domain_dash}.yml"
    site_path = "#{Figaro.env.sites_repo}/sites/#{filename}"
    @site_data = YAML.load_file(site_path).symbolize_keys
  end

  def load_from_fixture
    filename = "#{domain_dash}.yml"
    @site_data = YAML.load_file("#{Rails.root}/spec/fixtures/sites/#{filename}").symbolize_keys
  end

  def load_from_github
    site_dir = domain_dash
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
