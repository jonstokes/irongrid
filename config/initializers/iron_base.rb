PoolBoy.initialize_redis!

IronBase::Settings.configure do |config|
  config.env                   = Rails.env
  config.redis_url             = Figaro.env.ironsights_redis_url
  config.elasticsearch_url     = Figaro.env.elasticsearch_url_remote
  config.elasticsearch_index   = Figaro.env.index_name
  config.elasticsearch_pool_size = Figaro.env.elasticsearch_pool_size.to_i rescue 25
  config.logger                = Rails.env.production? ? nil : Rails.logger
  config.aws_access_key_id     = Figaro.env.aws_access_key_id
  config.aws_secret_access_key = Figaro.env.aws_secret_access_key
  config.aws_bucket_name       = 'irongrid-backup-production'
  config.aws_region            = 'us-east-1'
  config.snapshot_repository   = 'irongrid-backup'
  config.allow_nil_fields      = true
  config.redis_pool            = PoolBoy::Settings.redis_pool[:ironsights]
  config.client_options = {
      adapter:            :typhoeus,
      retry_on_failure:   true,
      parallel_manager:   Typhoeus::Hydra.new(max_concurrency: 30),
      transport_options: {
          request: {
              open_timeout: 5,
              timeout: 45
          }
      }
  }
end
