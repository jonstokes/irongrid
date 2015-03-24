def load_scripts
  SiteLibrary::Utils.data_dir = File.join(Rails.root, 'spec/fixtures/stretched/registrations')
  SiteLibrary::Utils.register_all
end
