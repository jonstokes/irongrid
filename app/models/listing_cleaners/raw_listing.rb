class RawListing < CoreModel
  attr_reader :adapter, :doc, :data

  delegate :[]=, to: :data
  delegate :each, to: :data

  def initialize(opts)
    @doc = DocReader.new(opts)
    @adapter = opts[:adapter]
    @data = {}
    parse_and_copy_attributes
  end

  def [](attr)
    @data[attr].present? ? @data[attr].strip.squeeze(" ") : nil
  end

  def to_s
    "#{@data}"
  end

  private

  def parse_and_copy_attributes
    adapter.each do |attribute, value|
      if should_copy_attribute?(attribute)
        @data[attribute] = value
      else
        @data[attribute] = parse_with_scraper_methods(value)
      end
    end
  end

  def parse_with_scraper_methods(method_arg_pairs)
    result = method_arg_pairs.each do |method_arg_pair|
      method_name = method_arg_pair["scraper_method"]
      arguments = method_arg_pair["arguments"]
      value = if arguments.try(:any?)
                 doc.send(method_name, arguments)
               else
                 doc.send(method_name)
               end
      break value if value
    end
    result.is_a?(String) ? result : nil
  end

  def should_copy_attribute?(attribute)
    # The value of these three attributes is always copied over directly to the raw_listing.
    # In other words, the value of these attributes is always declared in-line
    # in the adapter, and is never derived from executing a scraper_method against
    # a DocReader object.
    %w(seller_defaults validation digest_attributes).include?(attribute)
  end
end
