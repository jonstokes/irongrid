def convert_mapping(mapping)
  str = ""
  mapping.each do |term|
    str << "#{term},"
  end
  str[0..-2]
end

def synonyms
  calibers = Stretched::Mapping.find('handgun_calibers').data
  calibers.merge!(Stretched::Mapping.find('rifle_calibers').data)
  calibers.merge!(Stretched::Mapping.find('shotgun_calibers').data)
  calibers.merge!(Stretched::Mapping.find('rimfire_calibers').data)
  manufacturers = Stretched::Mapping.find('manufacturers').data

  caliber = []
  calibers.each do |term, mapping|
    next unless mapping
    caliber << "#{convert_mapping(mapping)} => #{term}"
  end

  manufacturer = []
  manufacturers.each do |term, mapping|
    next unless mapping
    manufacturer << "#{convert_mapping(mapping)} => #{term}"
  end

  product = caliber + manufacturer

  listing = []
  calibers.merge(manufacturers).each do |term, mapping|
    next unless mapping
    listing << "#{term},#{convert_mapping(mapping)}"
  end

  {
      listing: listing,
      product: product,
      caliber: caliber,
      manufacturer: manufacturer
  }
end


task create_index: :environment do
  IronBase::Settings.configure do |config|
    config.synonyms = synonyms
  end

  IronBase::Index.create(
      index: "ironsights-#{Rails.env}",
      filename: 'ironsights_v1'
  )
  IronBase::Listing.put_mapping
  IronBase::Product.put_mapping
  Location.put_mapping
end