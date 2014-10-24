class IndexObject
  INDEX_NAME = 'ironsights'

  def initialize(data)
    @data = Hashie::Mash.new(data)
  end

  def destroy
    # code to delete from index
  end

  def update(attrs)
    # TODO
  end

  def self.create(opts)
    response = client.index format_request(opts)
    response['created'] ? new(opts) : nil
  end

  def self.find(opts)
    response = client.search format_request(opts)
    response['hits']['total'].zero? ? nil : response['hits']['hits'].map {|hit| new_from_hit(hit)}
  end

  def self.new_from_hit(hit)
    obj = Hashie::Mash.new hit['_source']
    obj.id = hit['_id']
    obj
  end

  def self.format_request(body)
    {
      index: self::INDEX_NAME,
      type:  self::TYPE_NAME,
      body:  body
    }
  end

  def self.mapping
    Hashie::Mash.new YAML.load(ERB.new(File.read(self::MAPPING_FILE)).result)
  end

  def self.client
    $client ||= Elasticsearch::Client.new log: !Rails.env.production?
  end

  def self.put_mapping
    client.indices.put_mapping(format_request(mapping.to_hash))
  end

  private
  def method_missing(method_name, *args, &block)
    @data.send(method_name, args)
  end
end