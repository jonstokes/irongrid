task create_index: :environment do
  IronBase::Settings.configure do |config|
    config.synonyms = ElasticTools::Synonyms.synonyms
  end

  IronBase::Index.create(
      index: "ironsights-#{Rails.env}",
      filename: 'ironsights_v1'
  )
  IronBase::Listing.put_mapping
  IronBase::Product.put_mapping
  Location.put_mapping
end