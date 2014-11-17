IronBase::Settings.configure do |config|
  config.env                   = Rails.env
  config.redis_url             = Figaro.env.ironsights_redis_url
  config.elasticsearch_url     = Figaro.env.elasticsearch_url_remote
  config.elasticsearch_index   = Figaro.env.index_name
  config.logger                = Rails.logger
  config.aws_access_key_id     = Figaro.env.aws_access_key_id
  config.aws_secret_access_key = Figaro.env.aws_secret_access_key
  config.aws_bucket_name       = 'irongrid-backup-production'
  config.aws_region            = 'us-east-1'
  config.snapshot_repository   = 'irongrid-backup'
end
