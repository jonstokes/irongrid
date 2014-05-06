def create_site(domain, opts={})
  source = opts[:source] || :fixture
  site = Site.new(domain: domain, source: source)
  site.send(:write_to_redis)
  site
end

def create_sites
  YAML.load_file("#{Rails.root}/spec/fixtures/sites/manifest.yml").each do |domain|
    Site.new(domain: domain, source: :fixture).send(:write_to_redis)
  end
end
