require 'spec_helper'

describe Stretched::SessionQueue do

  before :each do
    Stretched::Registration.with_redis { |c| c.flushdb }
    Stretched::RateLimit.create_from_file("#{Rails.root}/spec/fixtures/stretched/registrations/rate_limits.yml")
    Stretched::SessionDefinition.create_from_file("#{Rails.root}/spec/fixtures/stretched/registrations/session_definitions.yml")
    Stretched::Schema.create_from_file("spec/fixtures/stretched/registrations/schemas/listing.json")
    Stretched::Schema.create_from_file("spec/fixtures/stretched/registrations/schemas/product_link.json")
    Stretched::ObjectAdapter.create_from_file("spec/fixtures/stretched/registrations/object_adapters/www--budsgunshop--com.yml")
    Stretched::Script.create_from_file("spec/fixtures/stretched/registrations/scripts/www--budsgunshop--com/object_adapter.rb")
    @store = Stretched::SessionQueue.find_or_create("www.retailer.com")
    @objects = YAML.load_file("#{Rails.root}/spec/fixtures/stretched/sessions/www--budsgunshop--com.yml")['sessions']
  end

  describe "#add", no_es: true do

    it "adds a batch of objects" do
      @store.add(@objects).should == 3
      expect(@store.size).to eq(3)
    end

    it "adds a single object" do
      expect(@store.add(@objects.first)).to be_true
      expect(@store.size).to eq(1)
    end

    it "does not add an object twice" do
      @store.add(@objects.first)
      expect(@store.add(@objects.first)).to be_zero
      expect(@store.size).to eq(1)
    end

    it "should add a previously popped object" do
      expect(@store.add(@objects)).to eq(3)
      object = @store.pop
      expect(@store.add(object)).to be_true
      expect(@store.size).to eq(3)
    end
  end

  describe "#clear", no_es: true do
    it "should clear the store" do
      @store.add(@objects).should == 3
      @store.size.should == 3
      @store.clear
      @store.should be_empty
    end
  end


  describe "#pop", no_es: true do
    it "should return an object and remove it from the queue" do
      @store.add(@objects)

      while object = @store.pop do
        key = Stretched::ObjectQueue.key(object)

        expect(object).not_to be_nil
        expect(@store.has_key?(key)).to be_false
        expect(Stretched::ObjectQueue.get(key)).to be_nil
        expect(object).to be_a(Hashie::Mash)
        expect(object.queue_name).to eq("www.budsgunshop.com")
        expect(object.session_definition).to be_a(Stretched::SessionDefinition)
        expect(object.object_adapters).to be_a(Array)
        expect(object.urls).to be_a(Array)
      end
    end

    it "returns nil if the queue is empty" do
      expect(@store.pop).to be_nil
    end
  end
end
