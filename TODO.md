#Bring up Stretched

compare launch lines on instances to new lines in README, and make any
fixes if needed

Bring down grid

RAILS_ENV=production rails c: 
  VALIDATOR_REDIS_POOL.with { |c| c.flushdb }
  STRETCHED_REDIS_POOL.with { |c| c.flushdb }
  IRONGRID_REDIS_POOL.with { |c| c.flushdb }
  Sidekiq.redis { |c| c.flushdb }

RAILS_ENV=production bundle exec rake stretched:register_all
RAILS_ENV=production bundle exec rake site:create_all

For each EC2 instance do:
  git fetch && git pull && git checkout js-dsl
  add STRETCHED_REDIS_URL on db 5 to config/application.yml
  boot services with new lines from README
