IronBase::Settings.configure do |config|
  config.env                   = Rails.env
  config.redis_url             = Figaro.env.ironsights_redis_url
  config.elasticsearch_url     = Figaro.env.elasticsearch_url_local
  config.elasticsearch_index   = Figaro.env.index_name
  config.logger                = Rails.logger
  config.synonyms              = (ElasticTools::Synonyms.synonyms rescue nil)
end
