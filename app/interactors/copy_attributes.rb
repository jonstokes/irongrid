class CopyAttributes
  include Interactor

  def call
    context.listing = Hashie::Mash.new
    map_json(
        context.listing_json,
        context.listing,
        json_mapping
    )
    context.message1 = context.listing_json.message1
    context.message2 = context.listing_json.message2
    context.message3 = context.listing_json.message3
    context.message4 = context.listing_json.message4
  end

  def json_mapping
    @json_to_es_mapping ||= Hashie::Mash.new YAML.load_file "#{Rails.root}/lib/object_mappings/listing.yml"
  end

  def map_json(json, listing, mapping)
    mapping.each do |key, value|
      if value.is_a?(Hashie::Mash)
        field = Hashie::Mash.new
        map_json(json, field, value)
        listing[key] = field unless field.empty?
      else
        next unless json[value]
        listing[key] = json[value]
      end
    end
  end
end

