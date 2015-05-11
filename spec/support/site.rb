RSpec.configure do |config|
  config.before(:each) do
    SiteLibrary::Site.clear_all
  end
end

def create_site(domain)
  SiteLibrary::Site::LoadFromLocal.call(domain: domain).site
end

def create_sites
  SiteLibrary::Site::CreateAll.call
end
