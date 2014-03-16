class RawListing < CoreModel
  attr_reader :site, :doc
  EXCLUDED_ATTRIBUTES = %w(seller_defaults validation digest_attributes category_matchers)

  def initialize(opts)
    @doc = DocReader.new(opts)
    @site = opts[:site]
    @raw_listing = {}
    parse_attributes
    copy_attributes
  end

  def [](attr)
    (@raw_listing[attr] && !@raw_listing[attr].blank?) ? @raw_listing[attr].strip.squeeze(" ") : nil
  end

  def []=(attr, val)
    @raw_listing[attr] = val
  end

  def each
    @raw_listing.each do |attr, val|
      yield attr, val
    end
  end

  def to_s
    "#{@raw_listing}"
  end

  private

  def parse_attributes
    attributes_to_parse.each do |attribute|
      exclude_list = process_excludes(attribute)
      process_includes(attribute, exclude_list)
    end
  end

  def attributes_to_parse
    site.adapter.select { |k, v| v.is_a?(Array) && v.first.is_a?(Hash) && v.first.has_key?("scraper_method") }.keys
  end

  def process_excludes(attribute)
    exclude_methods = site.send(attribute).select { |pair| pair["scraper_method"]["exclude_"] }
    exclude_list = []
    exclude_methods.each do |method_arg_pair|
      method_name = method_arg_pair["scraper_method"].split("exclude_").last
      arguments = method_arg_pair["arguments"]
      if arguments.try(:any?)
        result = doc.send(method_name, arguments)
        exclude_list << result if result
      else
        result = doc.send(method_name)
        exclude_list << result if result
      end
    end
    exclude_list.uniq
  end

  def process_includes(attribute, exclude_list)
    include_methods = site.send(attribute).reject { |pair| pair["scraper_method"]["exclude_"] }
    include_methods.each do |method_arg_pair|
      break if @raw_listing[attribute]
      method_name = method_arg_pair["scraper_method"]
      arguments = method_arg_pair["arguments"]
      result = arguments.try(:any?) ? doc.send(method_name, arguments) : doc.send(method_name)
      @raw_listing[attribute] = result unless exclude_list.include?(result)
    end
  end

  def copy_attributes
    attributes_to_copy.each { |attribute| @raw_listing[attribute] = site.send(attribute) }
  end

  def attributes_to_copy
    site.adapter.reject { |k, v| attributes_to_parse.include?(k) || EXCLUDED_ATTRIBUTES.include?(k) }.keys
  end
end
