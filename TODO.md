# Bring up stretched.io

Bring down grid

RAILS_ENV=production rails c: 
  VALIDATOR_REDIS_POOL.with { |c| c.flushdb }
  STRETCHED_REDIS_POOL.with { |c| c.flushdb }
  IRONGRID_REDIS_POOL.with { |c| c.flushdb }
  Sidekiq.redis { |c| c.flushdb }

Load irongrid loadables!

## /validator
RAILS_ENV=production bundle exec rake site:add_new
RAILS_ENV=production bundle exec rake stretched:register_all

## /stretched-node
RAILS_ENV=production bundle exec rake user:create_all

##/irongrid
RAILS_ENV=production bundle exec rake site:load_scripts


# EC2
## irongrid
git fetch && git pull && bundle install

## stretched
git clone https://github.com/jonstokes/stretched-node.git
bundle install

