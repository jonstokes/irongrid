module ObjectMapper
  def transform(opts)
    json, listing, mapping = opts[:source], opts[:destination], opts[:mapping]
    mapping.each do |key, value|
      if value.is_a?(Hashie::Mash)
        field = Hashie::Mash.new
        nopts = {
            source: json,
            destination: field,
            mapping: value
        }
        map_json(nopts)
        listing[key] = field unless field.empty?
      else
        next unless json[value]
        listing[key] = json[value]
      end
    end
  end
end
