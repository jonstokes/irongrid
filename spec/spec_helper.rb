# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'rspec/autorun'
require 'rubygems'
require 'bundler/setup'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

SiteLibrary.data = File.join(Rails.root, 'spec/fixtures/stretched/registrations')

RSpec.configure do |config|
  config.include(FactoryGirl::Syntax::Methods)
  config.fixture_path = "#{::Rails.root}/spec/fixtures"
  config.use_transactional_fixtures = false
  config.infer_base_class_for_anonymous_controllers = false
  config.order = 'random'
end

Rails.logger.info '########################################################################################################################################'
Rails.logger.info "############  Test Run #{Time.now}"
Rails.logger.info '########################################################################################################################################'


def updated_today?(listing)
  update = listing.updated_at.is_a?(String) ? Time.parse(listing.updated_at) : listing.updated_at
  update >= Time.now - 5.hours
end