RSpec.configure do |config|
  config.before(:each) do
    IronCore::Site.clear_all
  end
end

def create_site(domain, opts={})
  source = opts[:source] || :fixture
  site = IronCore::Site.create_from_source(domain, source: source)
  site.register
  site
end

def create_sites
  YAML.load_file("#{Rails.root}/spec/fixtures/sites/manifest.yml").each do |domain|
    IronCore::Site.create_from_source(domain, source: :fixture).register
  end
end
