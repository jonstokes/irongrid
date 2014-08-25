class Scrape
  include ActiveModel::Model
  include ActiveModel::Conversion
  include ActiveModel::Validations

  attr_reader :msg, :key
  attr_accessor :url, :domain, :page_adapter

  def initialize(opts={})
    opts = opts.to_h.symbolize_keys!
    @url, @domain, @page_adapter = opts[:url], opts[:domain], opts[:page_adapter]
    opts = opts.reject { |k, v| [:domain, :page_adapter].include?(k) }
    @msg = LinkMessage.new(opts)
  end

  def to_param
    key
  end

  def listing
    msg.page_attributes
  end

  def raw_listing
    msg.raw_attributes
  end

  def is_valid?
    msg.page_is_valid?
  end

  def not_found?
    msg.page_not_found?
  end

  def classified_sold?
    msg.page_classified_sold?
  end

  def save
    site = Site.new(domain: domain, source: :form, pool: :validator)
    return unless lint_adapter(page_adapter)
    site.update(page_adapter: YAML.load(page_adapter))
    @key = ScrapePageWorker.perform_async(
      domain:      domain,
      url:         url,
      site_source: :redis,
      site_pool:   :validator
    )
    true
  end

  def self.find(key)
    results = nil
    timeout = 25
    begin
      sleep 1
      results = ValidatorQueue.get(key)
    end until results || (timeout -= 1).zero?
    return Scrape.new unless results
    Scrape.new(results)
  end

  def self.new_record?
    true
  end

  def lint_adapter(source)
    tester = AdapterTests::Test.new(self)
    tester.validate_yaml(source)
    return if self.errors.messages.count > 0
    tester.check_for_stub_data(source)
    tester.check_digests(source)
    tester.check_adapter_format(source)
    self.errors.messages.count == 0
  end
end
