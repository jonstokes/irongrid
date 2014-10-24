class Product < IndexObject
  TYPE_NAME = 'product'
  MAPPING_FILE = "#{Rails.root}/lib/elasticsearch/mappings/product.yml"
end