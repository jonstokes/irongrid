class ExtractListingWithJsonAdapter
  include Interactor

  def setup
    context[:adapter] = (adapter_type == :feed) ? site.feed_adapter : site.page_adapter
    context[:json_adapter_output] = {}
  end

  def perform
    adapter.each do |attribute, value|
      if should_copy_value?(value)
        json_adapter_output[attribute] = value
      else
        json_adapter_output[attribute] = parse_with_scraper_methods(value)
      end
    end
    context[:doc] = nil
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
      break value if value.present?
    end
    clean_up(result)
  end

  def clean_up(result)
    result = result.strip.squeeze(" ") rescue nil
    result.present? ? result : nil
  end

  def should_copy_value?(value)
    # The value of these attributes is always copied over directly to the json_adapter_output.
    # In other words, the value of these attributes is declared in-line
    # in the adapter, and isn't derived from executing a scraper_method against
    # a DocReader object.
    !value.is_a?(Array) || !value.detect { |method_arg_pair| method_arg_pair["scraper_method"] }
  end
end
