class Site < CoreModel
  include Github
  include IrongridRedisPool

  attr_accessor :site_data

  SITE_ATTRIBUTES = [
    :name,
    :domain,
    :created_at,
    :updated_at,
    :read_at,
    :page_adapter,
    :feed_adapter,
    :read_with,
    :link_sources,
    :size,
    :active,
    :rate_limits,
    :read_interval,
    :commit_sha,
    :stats,
    :affiliate_link_tag,
    :timezone
  ]

  SITE_ATTRIBUTES.each do |key|
    define_method key do
      if key.to_s[/\_adapter/]
        var = eval("@#{key}")
        var ||= Adapter.new(@site_data[key])
      else
        @site_data[key]
      end
    end
  end

  def initialize(opts)
    raise "Domain required!" unless opts[:domain]
    @site_data = { domain: opts[:domain] }
    load_data!(opts[:source] || :redis)
  end

  def update(attrs)
    check_attributes(attrs)
    load_data!
    @site_data.merge!(attrs)
    write_to_redis
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

  def load_data!(source=:redis)
    case source
    when :redis
      load_from_redis
    when :local
      load_from_local
    when :git
      load_from_github
    when :fixture
      load_from_fixture
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
    @site_data = IRONGRID_REDIS_POOL.with do |conn|
      YAML.load(conn.get("site--#{domain}"))
    end.symbolize_keys
  end

  def load_from_local
    branch = ENV['SITE_BRANCH'] || "master"
    site_dir = domain.gsub(".","--")
    directory = "../ironsights-sites/sites/#{site_dir}"

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
    @site_data[:page_adapter] = YAML.load(fetch_file_from_github("sites/#{site_dir}/page_adapter.yml")) if File.exists?("sites/#{site_dir}/page_adapter.yml")
    @site_data[:feed_adapter] = YAML.load(fetch_file_from_github("sites/#{site_dir}/feed_adapter.yml")) if File.exists?("sites/#{site_dir}/feed_adapter.yml")
    @site_data[:link_sources] = YAML.load(fetch_file_from_github("sites/#{site_dir}/link_sources.yml"))
    @site_data[:rate_limits]  = YAML.load(fetch_file_from_github("sites/#{site_dir}/rate_limits.yml"))
    YAML.load(fetch_file_from_github("sites/#{site_dir}/attributes.yml")).each do |k, v|
      @site_data[k.to_sym] = v
    end
  end

  def write_to_redis
    IRONGRID_REDIS_POOL.with do |conn|
      conn.set("site--#{domain}", @site_data.to_yaml)
      conn.sadd("site--index", @site_data[:domain])
    end
  end
end
