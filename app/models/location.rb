class Location < IronBase::IndexedObject
  include Retryable
  include Notifier

  attr_accessor :data, :key

  REQUIRED_ATTRIBUTES = %w(id)

  DATA_KEYS = %w(
    city
    state
    country
    latitude
    longitude
    state_code
    postal_code
    country_code
    coordinates
  )

  DATA_KEYS.each do |key|
    define_method key do
      if key == "coordinates"
        "#{latitude},#{longitude}"
      else
        data[key]
      end
    end
  end

  def initialize(opts)
    super
    id.upcase!
  end

  def self.put(key)
    raise "Key cannot be nil!" unless key.present?
    id = key.upcase.strip

    loc = Location.find(id)
    return loc if loc

    loc = Location.new(id: id)
    return unless loc.fetch_data
    return loc.save ? loc : nil
  end

  def self.get(key)
    raise "Key cannot be nil!" unless key.present?
    id = key.upcase.strip

    Location.find(id)
  end

  def fetch_data
    return nil unless result = lookup_location(id)

    @data.merge!(
        "latitude"     => result.latitude,
        "longitude"    => result.longitude,
        "city"         => result.city,
        "state"        => result.state,
        "state_code"   => result.state_code,
        "postal_code"  => result.postal_code,
        "country"      => result.country,
        "country_code" => result.country_code
    )
  end

  def to_h
    data.merge("coordinates" => coordinates)
  end

  def self.default_location
    @@default_location ||= db { GeoData.get("UNKNOWN, UNITED STATES") }
  end

  private

  def lookup_location(item_location)
    zip = item_location[/\W\d{5}\W/] || item_location[/\W\d{5}/]
    zip = zip.gsub(/\W/, "").strip if zip
    state = item_location[/\W[A-Z]{2}\W/] || item_location[/\W[A-Z]{2}/]
    state = state.gsub(/\W/, "").strip if state

    if result = lookup_location_from_Google(item_location) || lookup_location_from_Google(zip) || lookup_location_from_Google(state)
      result
    else
      notify "Not able to retrieve coordinates for #{item_location} | #{zip} | #{state}."
      nil
    end
  end

  def lookup_location_from_Google(loc)
    return nil unless loc
    results = nil
    begin
      tries ||= 5
      results = retryable { Geocoder.search(loc) }
      sleep 1 if results.try(:empty?)
    end until results.try(:any?) || (tries -= 1).zero?
    results.try(:first)
  end
end
