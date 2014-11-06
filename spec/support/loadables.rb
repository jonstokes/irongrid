def load_scripts
  Dir["spec/fixtures/scripts/**/*.rb"].each do |filename|
    puts "# Loading script from #{filename}"
    Loadable::Script.create_from_file(filename)
  end
end
