class MergeJsonIntoProduct
  include Interactor
  include ObjectMapper

  def call
    context.fail! if context.product.complete?
    merge(
        source:      context.product_json,
        destination: context.product,
        mapping:     json_mapping
    )
    context.product.mpn = context.product_json.mpn
    context.product.sku = context.product_json.sku
    context.product.source = context.product_json.url
  end

  def json_mapping
    self.class.json_mapping
  end

  def self.json_mapping
    @json_to_es_mapping ||= Hashie::Mash.new YAML.load_file "#{Rails.root}/lib/object_mappings/product.yml"
  end

end