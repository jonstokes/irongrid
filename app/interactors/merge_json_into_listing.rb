class MergeJsonIntoListing
  include Interactor
  include ObjectMapper

  def call
    context.fail!(status: :invalid) unless context.listing_json.is_valid?

    transform(
        source: context.listing_json,
        destination: context.listing,
        mapping: json_mapping
    )
    context.listing.url = context.url
    context.listing.seller = {
        site_name: context.site.name,
        domain: context.site.domain
    }

    # TODO: put all the timezone translation logic into IronBase::Listing
    # TODO: Also add timezone to all auction listings in stretched
    fail(:not_found) if context.listing.auction_ended?
  end

  def json_mapping
    self.class.json_mapping
  end

  def self.json_mapping
    @json_to_es_mapping ||= Hashie::Mash.new YAML.load_file "#{Rails.root}/lib/object_mappings/listing.yml"
  end
end
