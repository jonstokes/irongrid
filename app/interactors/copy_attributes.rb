class CopyAttributes
  include Interactor
  include ObjectMapper

  def call
    transform(
        source: context.listing_json,
        destination: context.listing,
        mapping: json_mapping
    )

    context.message1 = context.listing_json.message1
    context.message2 = context.listing_json.message2
    context.message3 = context.listing_json.message3
    context.message4 = context.listing_json.message4
  end

  def json_mapping
    self.class.json_mapping
  end

  def self.json_mapping
    @json_to_es_mapping ||= Hashie::Mash.new YAML.load_file "#{Rails.root}/lib/object_mappings/listing.yml"
  end
end

