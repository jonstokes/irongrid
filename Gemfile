source 'http://rubygems.org'
source "https://7efe68ea:9c90e496@gems.contribsys.com/"
ruby '2.0.0', :engine => 'jruby', :engine_version => '1.7.19'

gem "rails", "4.0.2"
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
gem 'yell-rails'
gem 'yell-adapters-syslog'
gem 'interactor', '3.1.0'
gem 'poltergeist'
gem 'capybara'
gem 'hashie'
gem 'tokenizer'
gem 'logglier'
gem 'elasticsearch'
gem 'elasticsearch-rails'

#gem 'iron_base', git: "https://339de3a38d1cf30ca405bdc7faddc135dfefe1f6:x-oauth-basic@github.com/jonstokes/iron_base.git", branch: 'master'
gem 'iron_base', path: "../iron_base"
#gem 'stretched', git: "https://339de3a38d1cf30ca405bdc7faddc135dfefe1f6:x-oauth-basic@github.com/jonstokes/stretched-rb.git"
gem 'stretched', path: "/Users/jstokes/Local/Repositories/stretched-rb"
gem 'retryable', git: "https://github.com/jonstokes/retryable.git"
gem 'sunbro', git: "https://github.com/jonstokes/sunbro.git"


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
