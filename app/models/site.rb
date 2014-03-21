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
#  scrape_with_service :string(255)
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

  attr_accessor :domain, :site_data

  def initialize(opts)
    @domain = opts[:domain]
    @site_data = {}
    case opts[:source]
    when :redis
      @site_data = IRONGRID_REDIS_POOL.with { |conn| JSON.load(conn.get("site--#{domain}")) }.symbolize_keys
    when :local
      load_local_source
    when :git
      #load_github_source
    when :fixture
      load_fixture
    end
  end

  def digest_attributes(defaults)
    return defaults unless attrs = adapter["digest_attributes"]
    return attrs unless attrs.include?("defaults")
    attrs = defaults + attrs # order matters here, so no +=
    attrs.delete("defaults")
    attrs
  end

  def active?
    self.active
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

  def should_read?
    return true unless self.read_at && self.read_interval
    Time.now > self.read_at + self.read_interval
  end

  def mark_read!
    update_attribute(:read_at, Time.now)
  end

  def read_at
    return Time.parse(@site_data["read_at"]) if @site_data["read_at"]
    10.days.ago
  end

  def default_seller_timezone
    # This is necessary because ActiveRecord::Base has a default_timezone method
    return nil unless seller_defaults
    self.seller_defaults["timezone"]
  end

  def respond_to?(method_id, include_private = false)
    @respond_to && @respond_to.include?(method_id) ? true : super
  end

  private

  def method_missing(method_id, *arguments, &block)
    @respond_to ||= Set.new
    if @site_data.has_key?(method_id)
      @respond_to << method_id
      @site_data[method_id]
    elsif adapter.has_key?(method_id.to_s)
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

  def load_local_source
    branch = ENV['SITE_BRANCH'] || "master"
    site_dir = domain.gsub(".","--")
    directory = "../ironsights-sites/sites/#{site_dir}"

    @site_data[:adapter] = YAML.load_file("#{directory}/adapter_source.yml")
    @site_data[:service_options] = YAML.load_file("#{directory}/service_options.yml")
    @site_data[:rate_limits] = YAML.load_file("#{directory}/rate_limits.yml")
    YAML.load_file("#{directory}/rate_limits.yml").each do |k, v|
      @site_data[k.to_sym] == v
    end
  end

  def load_fixture
    filename = domain.gsub(".","--") + ".yml"
    @site_data = YAML.load_file("#{Rails.root}/spec/fixtures/sites/#{filename}").attributes
    @site_data.delete("id")
    @site_data.delete("created_at")
    @site_data.delete("updated_at")
  end

  def load_github_source
    branch = ENV['SITE_BRANCH'] || "master"
    site_dir = domain.gsub(".","--")
    url_prefix = "https://raw.github.com/jonstokes/ironsights-sites/#{branch}/sites/#{site_dir}"
    site_data_hash = {}

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
  
  def update_attribute(attr, value)
    @site_data[attr] = value
    write_to_redis
  end

  def write_to_redis
    IRONGRID_REDIS_POOL.with { |conn| conn.set("site--#{domain}", @site_data.to_json) }
  end

  def filenames
    %w(adapter_source.yml attributes.yml service_options.yml rate_limits.yml)
  end
end
