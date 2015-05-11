source 'http://rubygems.org'
source "https://7efe68ea:9c90e496@gems.contribsys.com/"

ruby '2.0.0', :engine => 'jruby', :engine_version => '1.7.18'

gem "rails", "4.2.0"
gem 'figaro'
gem "protected_attributes"
gem 'redis'
gem 'robotex'
gem 'nokogiri'
gem 'american_date'
gem 'sidekiq'
gem 'sidekiq-pro'
gem 'airbrake'
gem 'aws-sdk'
gem 'net-http-persistent'
gem "geocoder"
gem 'connection_pool'
gem 'stringex'
gem 'interactor', '3.1.0'
gem 'poltergeist'
gem 'capybara'
gem 'hashie'
gem 'tokenizer'
gem 'elasticsearch'
gem 'elasticsearch-rails'
gem 'syslogger', '~> 1.6.0'
gem 'retryable'

gem 'stretched' ,git: "https://339de3a38d1cf30ca405bdc7faddc135dfefe1f6:x-oauth-basic@github.com/jonstokes/stretched-rb.git"

# IronGrid basic dependencies
gem 'shout', git: "https://339de3a38d1cf30ca405bdc7faddc135dfefe1f6:x-oauth-basic@github.com/jonstokes/shout.git"
gem 'pool_boy', git: "https://339de3a38d1cf30ca405bdc7faddc135dfefe1f6:x-oauth-basic@github.com/jonstokes/pool_boy.git"
gem 'redis_objects', git: "https://339de3a38d1cf30ca405bdc7faddc135dfefe1f6:x-oauth-basic@github.com/jonstokes/redis_objects.git"
gem 'sunbro', git: "https://339de3a38d1cf30ca405bdc7faddc135dfefe1f6:x-oauth-basic@github.com/jonstokes/sunbro.git"
gem 'bellbro', git: 'https://339de3a38d1cf30ca405bdc7faddc135dfefe1f6:x-oauth-basic@github.com/jonstokes/bellbro.git'

# IronGrid gems
gem 'iron_core', git: "https://339de3a38d1cf30ca405bdc7faddc135dfefe1f6:x-oauth-basic@github.com/jonstokes/iron_core.git"
gem 'iron_base', git: 'https://339de3a38d1cf30ca405bdc7faddc135dfefe1f6:x-oauth-basic@github.com/jonstokes/iron_base.git'
gem 'site_library', git: 'https://339de3a38d1cf30ca405bdc7faddc135dfefe1f6:x-oauth-basic@github.com/jonstokes/site_library.git'

## Local copies

#gem 'stretched', path: '../stretched-rb'

#gem 'shout', path: '../shout'
#gem 'pool_boy', path: '../pool_boy'
#gem 'redis_objects', path: '../redis_objects'

#gem 'sunbro', path: '../sunbro'
#gem 'bellbro', path: '../bellbro'
#gem 'iron_core', path: '../iron_core'
#gem 'iron_base', path: '../iron_base'
#gem 'site_library', path: '../site_library'

# JRuby-specific gems
gem 'execjs'
gem 'therubyrhino'
gem 'jruby-openssl'
gem 'activerecord-jdbc-adapter', '1.3.10'
gem 'activerecord-jdbcpostgresql-adapter', '1.3.10'
gem 'jdbc-postgres'
gem 'thread_safe'
gem 'image_voodoo'

group :development do
  gem 'annotate'
  gem 'awesome_print'
end

group :development, :test do
  gem 'rspec-rails'
  gem 'rspec-mocks'
end

group :test do
  gem 'cucumber-rails', :require => false
  gem 'database_cleaner'
  gem 'spork'
  gem 'launchy'
  gem 'rake'
  gem 'rdoc'
  gem "factory_girl_rails"
  gem "ffaker"
  gem 'mocktra'
end
