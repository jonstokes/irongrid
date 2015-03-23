def load_scripts
  user = "test@irongrid.com"
  Dir["spec/fixtures/loaded/scripts/**/*.rb"].each do |filename|
    Loaded::Script.create_from_file(filename, user)
  end

  Dir["spec/fixtures/loaded/extensions/**/*.rb"].each do |filename|
    Loaded::Extension.create_from_file(filename, user)
  end

  Loaded::Extension.register_all(user)
end
