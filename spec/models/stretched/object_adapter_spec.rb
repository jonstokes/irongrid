require 'spec_helper'

describe Stretched::ObjectAdapter do

  before :each do
    Stretched::Registration.with_redis { |conn| conn.flushdb }
  end

  describe "#initialize" do
    it "creates a new empty Registration object" do
      Stretched::Schema.create(key: "test-schema-1")
      registration = Stretched::ObjectAdapter.new(
        key: "test-1",
        data: {
          "schema" => "test-schema-1",
          "xpath" => "/html",
          "scripts" => ["a", "b", "c"]
        }
      )
      expect(registration).to be_a(Stretched::ObjectAdapter)
      expect(registration.key).to eq("test-1")
      expect(registration.data).not_to be_empty
      expect(registration.xpath).to eq("/html")
      expect(registration.attribute_setters).to be_a(Hash)
      expect(registration.scripts).to eq(["a", "b", "c"])
      expect(registration.schema).to be_a(Stretched::Schema)
      expect(registration.schema.key).to eq("test-schema-1")
    end
  end

  describe "::create" do
    it "creates a new registration object in the db and returns it" do
      registration = Stretched::ObjectAdapter.create(key: "test-1", data: {"key" => "value"})
      reg = Stretched::ObjectAdapter.find(registration.key)
      expect(reg).to be_a(Stretched::ObjectAdapter)
      expect(reg.data).to eq({ "key" => "value" })
    end
  end

  describe "::find" do
    it "finds an object that has previously been registered" do
      registration = Stretched::ObjectAdapter.new(key: "test-1")
      registration.data = { "key" => "value" }
      registration.save

      reg = nil
      expect {
        reg = Stretched::ObjectAdapter.find(registration.key)
      }.not_to raise_error

      expect(reg).to be_a(Stretched::ObjectAdapter)
      expect(reg.data).to eq({ "key" => "value" })
    end
  end

end

