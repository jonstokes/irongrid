# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'rspec/autorun'
require 'rubygems'
require 'bundler/setup'
require 'fakeweb'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }


SPEC_DOMAIN = 'http://www.example.com/'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

RSpec.configure do |config|
  config.include(FactoryGirl::Syntax::Methods)

  # ## Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = "random"
end

def load_listing_source(type, seller, item)
  url = html = nil
  pt = create_parser_test(item)
  create_site_from_repo(seller) unless Site.find_by_domain(seller)
  url = pt.url
  html = open(pt.html_on_s3).read
  { :url => url, :html => html }
end

def pages_from_parser_tests(opts)
  ParserTest.where(opts[:conditions]).limit(opts[:limit]).map do |pt|
    {
      url: pt.url,
      domain: pt.seller_domain,
      html: open(pt.html_on_s3).read
    }
  end
end

def create_scraper_double(new_attrs)
  new_page = double()
  new_page.stub("listing") { new_attrs }
  new_page.stub("image") { new_attrs["image"] }
  new_page.stub("full_image_url") { "http://rspec.com/foobar.jpg" }
  new_page.stub("cdn_name") { get_cdn_name(new_page.full_image_url) }
  new_page.stub("cdn_image_url") { get_cdn_image_url(new_page.cdn_name) }
  new_page.stub("url") { new_attrs["url"] }
  new_page
end

def populate_link(filename, cdn_name)
  config = YAML.load(File.read('config/aws.yml'))[Rails.env]
  aws_options = {
    :aws_access_key_id     => config["access_key_id"],
    :aws_secret_access_key => config["secret_access_key"],
  }
  s3 = AWS::S3.new(aws_options)
  file = File.open(filename)
  s3.buckets['scoperrific-rspec'].objects[cdn_name].delete if s3.buckets['scoperrific-rspec'].objects[filename].exists?
  s3.buckets['scoperrific-rspec'].objects[cdn_name].write(:file => file, :acl => :public_read, :reduced_redundancy => true)
  s3.buckets['scoperrific-rspec'].objects[cdn_name].public_url
end

def write_page_queue_to_database()
  CreateListingsWorker.new.perform
end

def create_parser_tests
  YAML.load_file("#{Rails.root}/spec/fixtures/parser_tests/manifest.yml").each do |filename|
    attrs = YAML.load_file("#{Rails.root}/spec/fixtures/parser_tests/#{filename}.yml").attributes
    attrs.delete("id")
    attrs.delete("created_at")
    attrs.delete("updated_at")
    ParserTest.create(attrs)
  end
end

def create_parser_test(title)
  pt = nil
  YAML.load_file("#{Rails.root}/spec/fixtures/parser_tests/manifest.yml").each do |filename|
    next if pt
    attrs = YAML.load_file("#{Rails.root}/spec/fixtures/parser_tests/#{filename}.yml").attributes
    if attrs["title"] == title
      attrs.delete("id")
      attrs.delete("created_at")
      attrs.delete("updated_at")
      pt = ParserTest.create(attrs)
    end
  end
  pt
end

def create_site_from_repo(domain)
  filename = domain.gsub(".","--") + ".yml"
  attrs = YAML.load_file("#{Rails.root}/spec/fixtures/sites/#{filename}").attributes
  attrs.delete("id")
  attrs.delete("created_at")
  attrs.delete("updated_at")
  Site.create(attrs)
end

def create_sites
  YAML.load_file("#{Rails.root}/spec/fixtures/sites/manifest.yml").each do |domain|
    attrs = YAML.load_file("#{Rails.root}/spec/fixtures/sites/#{domain.gsub(".","--")}.yml").attributes
    attrs.delete("id")
    attrs.delete("created_at")
    attrs.delete("updated_at")
    Site.create(attrs)
  end
end
