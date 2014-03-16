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

class Site < ActiveRecord::Base
  include ConnectionWrapper
  include Retryable
  include Notifier

  has_many :listings

  attr_accessible :name, :domain, :adapter_source, :read_at, :engine, :scrape_with_service, :service_options
  attr_accessible :size, :active, :read_interval, :commit_sha, :rate_limits

  serialize :service_options, Hash
  serialize :rate_limits, Hash


  def adapter
    @adapter ||= YAML.load(adapter_source)
  end

  def respond_to?(method_id, include_private = false)
    @respond_to && @respond_to.include?(method_id) ? true : super
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
    db { self.update_attribute(:read_at, Time.now) }
  end

  def default_seller_timezone
    # This is necessary because ActiveRecord::Base has a default_timezone method
    return nil unless seller_defaults
    self.seller_defaults["timezone"]
  end

  def self.get_all_classifieds_sites
    db { Site.all.select { |site| site.validation["classified"] } }
  end

  def self.get_all_sites_for_service(service)
    db { Site.where(scrape_with_service: [service.to_s], active: true) }
  end

  private

  def method_missing(method_id, *arguments, &block)
    super unless adapter
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

end
