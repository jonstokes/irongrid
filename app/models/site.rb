# == Schema Information
#
# Table name: sites
#
#  id                  :integer          not null, primary key
#  name                :string(255)      not null
#  domain              :string(255)      not null
#  adapter_source      :text             not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  engine              :string(255)
#  read_with :string(255)
#  service_options     :text
#  size                :integer
#  active              :boolean
#  rate_limits         :text
#  read_at             :datetime
#  read_interval       :integer
#  commit_sha          :string(255)
#

class Site
  include Retryable
  include Notifier

  attr_accessor :site_data

  SITE_ATTRIBUTES = [
    :name,
    :domain,
    :created_at,
    :updated_at,
    :read_at,
    :adapter,
    :read_with,
    :service_options,
    :size,
    :active,
    :rate_limits,
    :read_interval,
    :commit_sha
  ]

  SITE_ATTRIBUTES.each do |key|
    define_method key do
      @site_data[key]
    end
  end

  def initialize(opts)
    source = opts[:source] || :redis
    opts.delete(:source)
    check_attributes(opts)
    raise "Domain required!" unless opts[:domain]
    @site_data = {}
    @site_data.merge!(opts)

    case source
    when :redis
      load_from_redis
    when :local
      load_from_local
    when :git
      #load_from_github
    when :fixture
      #load_from_fixture
    when :db
      #load_from_db
    end
  end

  def update_attribute(attr, value)
    check_attributes(attr)
    @site_data[attr] = value
    write_to_redis
  end

  def update(attrs)
    check_attributes(attrs)
    @site_data.merge!(attrs)
    write_to_redis
  end

  def digest_attributes(defaults)
    return defaults unless attrs = adapter["digest_attributes"]
    return attrs unless attrs.include?("defaults")
    attrs = defaults + attrs # order matters here, so no +=
    attrs.delete("defaults")
    attrs
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
    update_attribute(:read_at, Time.now.utc)
  end

  def default_seller_timezone
    # This is necessary because ActiveRecord::Base has a default_timezone method
    return nil unless seller_defaults
    self.seller_defaults["timezone"]
  end

  def should_read?
    return true unless read_at && read_interval
    Time.now.utc > read_at + read_interval
  end

  def active?
    active
  end

  def respond_to?(method_id, include_private = false)
    @respond_to && @respond_to.include?(method_id) ? true : super
  end

  def self.domains
    with_redis { |conn| conn.smembers "site--index" }
  end

  def self.active
    domains.map do |domain|
      site = Site.new(domain: domain)
      site.active? ? site : nil
    end.compact
  end

  private

  def check_attributes(obj)
    if obj.is_a?(Hash)
      obj.keys.each { |attr| raise "Invalid attribute #{attr}" unless SITE_ATTRIBUTES.include?(attr) }
    else
      attr = obj.to_sym
      raise "Invalid attribute #{attr}" unless SITE_ATTRIBUTES.include?(attr)
    end
  end

  def method_missing(method_id, *arguments, &block)
    @respond_to ||= Set.new
    if adapter.has_key?(method_id.to_s)
      @respond_to << method_id
      adapter[method_id.to_s]
    elsif method_id.to_s["default_"] && self.seller_defaults
      @respond_to << method_id
      default = "#{method_id}".split("default_").last
      self.seller_defaults[default]
    else
      nil
    end
  end

  def load_from_redis
    @site_data = IRONGRID_REDIS_POOL.with { |conn| YAML.load(conn.get("site--#{domain}")) }.symbolize_keys
  end

  def load_from_local
    branch = ENV['SITE_BRANCH'] || "master"
    site_dir = domain.gsub(".","--")
    directory = "../ironsights-sites/sites/#{site_dir}"

    @site_data[:adapter]         = YAML.load_file("#{directory}/adapter_source.yml")
    @site_data[:service_options] = YAML.load_file("#{directory}/service_options.yml")
    @site_data[:rate_limits]     = YAML.load_file("#{directory}/rate_limits.yml")
    YAML.load_file("#{directory}/attributes.yml").each do |k, v|
      @site_data[k.to_sym] = v
    end
  end

  def load_from_fixture
    filename = domain.gsub(".","--") + ".yml"
    @site_data = YAML.load_file("#{Rails.root}/spec/fixtures/sites/#{filename}").attributes
    @site_data.delete("id")
    @site_data.delete("created_at")
    @site_data.delete("updated_at")
  end

  def load_from_github
    branch = ENV['SITE_BRANCH'] || "master"
    site_dir = domain.gsub(".","--")
    url_prefix = "https://raw.github.com/jonstokes/ironsights-sites/#{branch}/sites/#{site_dir}"
    site_data_hash = {}
    filenames = %w(adapter_source.yml attributes.yml service_options.yml rate_limits.yml)
    filenames.each do |filename|
      begin
        file = open("#{url_prefix}/#{filename}", http_basic_authentication: ["jonstokes", "2bdb479801fc520e3ae90a2aecd53be3a89cc2e1"]).read
        site_data_hash.merge!(YAML.load(file))
      rescue OpenURI::HTTPError
        return nil
      end
    end
    site_data_hash
  end

  def load_from_db
    # Be sure to copy over timestamps, read_at, and commit_sha
  end

  def write_to_redis
    IRONGRID_REDIS_POOL.with do |conn|
      conn.set("site--#{domain}", @site_data.to_yaml)
      conn.sadd("site--index", @site_data[:domain])
    end
  end

  def self.with_redis(&block)
    retryable(sleep: 0.5) do
      IRONGRID_REDIS_POOL.with &block
    end
  end
end
