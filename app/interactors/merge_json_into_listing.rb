class MergeJsonIntoListing
  include Interactor
  include ObjectMapper

  def call
    context.fail!(status: :invalid) unless context.listing_json.valid
    context.listing.timezone = context.site.timezone
    transform(
        source:      context.listing_json,
        destination: context.listing,
        mapping:     json_mapping
    )
    context.listing.url = context.url
    context.listing.seller = {
        site_name: context.site.name,
        domain:    context.site.domain
    }
    context.fail!(status: :auction_ended) if context.listing.auction_ended?
  end

  def json_mapping
    self.class.json_mapping
  end

  def self.json_mapping
    @json_to_es_mapping ||= Hashie::Mash.new YAML.load_file "#{Rails.root}/lib/object_mappings/listing.yml"
  end
end
