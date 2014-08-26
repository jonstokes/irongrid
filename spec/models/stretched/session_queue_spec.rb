require 'spec_helper'

describe Stretched::SessionQueue do

  before :each do
    Stretched::Registration.with_redis { |c| c.flushdb }
    register_stretched_globals
    Stretched::Script.register_from_file("spec/fixtures/stretched/registrations/scripts/www--budsgunshop--com/object_adapter.rb")
    register_site "www.budsgunshop.com"
    @store = Stretched::SessionQueue.find_or_create("www.budsgunshop.com")
    @objects = YAML.load_file("#{Rails.root}/spec/fixtures/sites/www--budsgunshop--com.yml")['sessions']
  end

  describe "#add", no_es: true do

    it "adds a batch of objects" do
      expect(@store.add(@objects).count).to eq(5)
      expect(@store.size).to eq(5)
    end

    it "adds a single object" do
      @objects.each_with_index do |object, i|
        expect(@store.add(object).count).to eq(1)
        expect(@store.size).to eq(i + 1)
      end
    end

    it "does not add an object twice" do
      @store.add(@objects.first)
      expect(@store.add(@objects.first)).to be_empty
      expect(@store.size).to eq(1)
    end

    it "should add a previously popped object" do
      expect(@store.add(@objects.first).count).to eq(1)
      expect(@store.size).to eq(1)
      @store.pop
      expect(@store.size).to eq(0)
      expect(@store.add(@objects.first)).not_to be_empty
      expect(@store.size).to eq(1)
    end
  end

  describe "#clear", no_es: true do
    it "should clear the store" do
      @store.add(@objects).count.should == 5
      @store.size.should == 5
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
        expect(object).to be_a(Stretched::Session)
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
