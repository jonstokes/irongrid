require 'spec_helper'

describe Stretched::Registration do

  before :each do
    Stretched::Registration.with_redis { |conn| conn.flushdb }
  end

  describe "#initialize" do
    it "creates a new empty Registration object" do
      registration = Stretched::Registration.new(type: "Registration", key: "test-1")
      expect(registration).to be_a(Stretched::Registration)
      expect(registration.key).to eq("test-1")
      expect(registration.registration_type).to eq("Registration")
      expect(registration.data).to be_empty
    end

    it "Loads a keyref and merges its attributes" do
      registration1 = Stretched::Registration.create(
        type: "Registration",
        key: "test-1",
        data: {"key1" => "value"}
      )
      registration2 = Stretched::Registration.create(
        :type => "Registration",
        :key => "test-2",
        :data => {
          "$key" => "test-1",
          "key2" => "value2"
        }
      )

      expect(registration2.data).to eq(
        {
          "key1" => "value",
          "key2" => "value2"
        }
      )
    end
  end

  describe "#save" do
    it "saves a registration object to redis" do
      registration = Stretched::Registration.new(type: "Registration", key: "test-1")
      registration.data = { "key" => "value" }

      expect(registration.save).to be_true
      key = value = nil

      Stretched::Registration.with_redis do |conn|
        key = conn.spop("registrations")
        value = conn.get("registrations::#{key}")
      end

      expect(key).to eq("Registration::test-1")
      expect(YAML.load(value)).to eq({ "key" => "value" })
    end
  end

  describe "#destroy" do
    it "deletes a registration object from redis" do
      registration = Stretched::Registration.new(type: "Registration", key: "test-1")
      registration.data = { "key" => "value" }

      registration.save
      registration.destroy

      key = value = nil

      Stretched::Registration.with_redis do |conn|
        key = conn.spop("registrations")
        value = conn.get("registrations::#{key}")
      end

      expect(key).to be_nil
      expect(value).to be_nil
    end
  end

  describe "::load_file" do
    it "loads a YAML or JSON schema file and returns an array of any registrations it finds" do
      filename = "#{Rails.root}/spec/fixtures/stretched/registrations/schemas/listing.json"
      results = Stretched::Registration.load_file(filename)
      expect(results).to be_a(Array)
      expect(results.size).to eq(1)

      reg = results.first
      expect(reg.type).to eq("Schema")
      expect(reg[:key]).to eq("Listing")
      expect(reg.data['description']).to eq('Schema for product listing JSON object')
    end

    it "loads a YAML or JSON object adapter file and returns an array of any registrations it finds" do
      filename = "#{Rails.root}/spec/fixtures/stretched/registrations/schemas/listing.json"
      Stretched::Registration.create_from_file(filename)


      filename = "#{Rails.root}/spec/fixtures/stretched/registrations/object_adapters/globals.yml"
      results = Stretched::Registration.load_file(filename)
      expect(results).to be_a(Array)
      expect(results.size).to eq(2)

      reg = results.first
      expect(reg.type).to eq("ObjectAdapter")
      expect(reg[:key]).to eq("globals/product_link")
      expect(reg.data.xpath).to eq('//span[@class="productListing-productname"]/a')
      expect(reg.data.schema).not_to be_nil
    end
  end

  describe "::create_from_file" do
    it "loads a YAML or JSON schema file and creates any registrations it finds" do
      filename = "#{Rails.root}/spec/fixtures/stretched/registrations/schemas/listing.json"
      Stretched::Registration.create_from_file(filename)
      reg = Stretched::Schema.find("Listing")
      expect(Stretched::Registration.count).to eq(1)
      expect(reg).to be_a(Stretched::Schema)
      expect(reg.key).to eq("Listing")
      expect(reg.data['description']).to eq('Schema for product listing JSON object')
    end

    it "loads a YAML or JSON object_adapter file and creates any registrations it finds" do
      filename = "#{Rails.root}/spec/fixtures/stretched/registrations/schemas/listing.json"
      Stretched::Registration.create_from_file(filename)
      filename = "#{Rails.root}/spec/fixtures/stretched/registrations/object_adapters/globals.yml"
      Stretched::Registration.create_from_file(filename)

      expect(Stretched::Registration.count).to eq(3)
      reg = Stretched::ObjectAdapter.find("globals/product_page")
      expect(reg).to be_a(Stretched::ObjectAdapter)
      expect(reg.key).to eq("globals/product_page")
      expect(reg.xpath).to eq('/html')
    end
  end

  describe "::create" do
    it "creates a new registration object in the db and returns it" do
      registration = Stretched::Registration.create(type: "Registration", key: "test-1", data: {"key" => "value"})
      reg = Stretched::Registration.find(type: "Registration", key: registration.key)
      expect(reg).to be_a(Stretched::Registration)
      expect(reg.data).to eq({ "key" => "value" })
    end
  end

  describe "::find" do
    it "finds an object that has previously been registered" do
      registration = Stretched::Registration.new(type: "Registration", key: "test-1")
      registration.data = { "key" => "value" }
      registration.save

      reg = nil
      expect {
        reg = Stretched::Registration.find(type: "Registration", key: registration.key)
      }.not_to raise_error

      expect(reg).to be_a(Stretched::Registration)
      expect(reg.data).to eq({ "key" => "value" })
    end
  end

end

