RSpec.configure do |config|
  config.before :all do
    IronBase::Index.delete(index: IronBase::Settings.elasticsearch_index) rescue nil
    register_globals
    IronBase::Settings.configure {|c| c.synonyms = ElasticTools::Synonyms.synonyms}
  end

  config.before :each do
    IronBase::Index.create(index: IronBase::Settings.elasticsearch_index, filename: 'ironsights_v1.yml')
    IronBase::Listing.put_mapping
  end

  config.after :each do
    IronBase::Index.delete(index: IronBase::Settings.elasticsearch_index) rescue nil
  end
end
