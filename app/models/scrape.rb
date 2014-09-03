class Scrape
  include ActiveModel::Model
  include ActiveModel::Conversion
  include ActiveModel::Validations

  attr_reader :key
  attr_accessor :session, :site_data

  def initialize(opts={})
    opts = opts.to_h.symbolize_keys!
    @session, @site_data, @data = opts[:session], opts[:site_data], opts[:data]
  end

  def data
    @mashed_data ||= Hashie::Mash.new(@data)
  end

  def to_param
    key
  end

  def save
    return unless lint_adapter
    site = Site.new(site_data: site_data, source: :form, pool: :validator)
    @key = ScrapePageWorker.perform_async(
      domain: site_data['domain'],
      session: session,
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
    Scrape.new(data: results)
  end

  def self.new_record?
    true
  end

  def lint_adapter
    tester = AdapterTests::Test.new(self)
    #tester.validate_yaml(source)
    #return if self.errors.messages.count > 0
    #tester.check_for_stub_data(source)
    #tester.check_digests(source)
    tester.check_adapter_format(site_data)
    self.errors.messages.count == 0
  end
end
