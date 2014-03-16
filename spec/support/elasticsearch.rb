RSpec.configure do |config|
  config.before :each do
    unless example.metadata[:no_es] == true
      Listing.recreate_index
    end
  end
end
