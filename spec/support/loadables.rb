def load_scripts
  SiteLibrary.data = File.join(Rails.root, 'spec/fixtures/registrations')
  SiteLibrary::StretchedUtils.register_all
end
