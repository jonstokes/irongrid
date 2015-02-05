user = Figaro.env.stretched_user || "#{Rails.env}@ironsights.com"
pool = Figaro.env.redis_pool.to_i rescue 10

Stretched::Settings.configure do |config|
  config.user = user
  config.redis_pool_size = pool
  config.redis_url = Figaro.env.stretched_redis_url
end

