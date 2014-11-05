IronBase::Settings.configure do |config|
  config.env                   = Rails.env
  config.redis_url             = Figaro.env.ironsights_redis_url
  config.elasticsearch_url     = Figaro.env.elasticsearch_url_local
  config.elasticsearch_index   = Listing.index_name
  config.logger                = Rails.logger
end
