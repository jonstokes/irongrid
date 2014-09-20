require 'spec_helper'

describe Stretched::ObjectAdapter do

  before :each do
    @user = "test@ironsights.com"
    Stretched::Registration.with_redis { |conn| conn.flushdb }
    Stretched::Schema.register_from_file(@user, "#{Rails.root}/spec/fixtures/stretched/registrations/schemas/listing.json")
  end

  describe "#initialize" do
    it "creates a new empty Registration object with a schema declared in-line" do
      registration = Stretched::ObjectAdapter.new(
        key: "test-1",
        user: @user,
        data: {
          "schema" => {
            "test-schema-1" => { "$key" => "Listing" }
          },
          "xpath" => "/html",
          "queue" => "www.retailer.com",
          "scripts" => ["a", "b", "c"],
          "attribute" => { "title" => { "type" => "string"}}
        }
      )
      expect(registration).to be_a(Stretched::ObjectAdapter)
      expect(registration.key).to eq("test-1")
      expect(registration.data).not_to be_empty
      expect(registration.xpath).to eq("/html")
      expect(registration.queue).to eq("www.retailer.com")
      expect(registration.attribute_setters).to be_a(Hash)
      expect(registration.scripts).to eq(["a", "b", "c"])
      expect(registration.schema).to be_a(Stretched::Schema)
      expect(registration.schema.key).to eq("test-schema-1")
      expect(registration.schema.data).not_to be_nil
      expect(registration.schema.data).not_to be_empty
    end

    it "creates a new empty Registration object with a schema reference" do
      registration = Stretched::ObjectAdapter.new(
        key: "test-1",
        user: @user,
        data: {
          "schema" => "Listing",
          "xpath" => "/html",
          "scripts" => ["a", "b", "c"],
          "attribute" => { "title" => { "type" => "string"}}
        }
      )
      expect(registration).to be_a(Stretched::ObjectAdapter)
      expect(registration.key).to eq("test-1")
      expect(registration.data).not_to be_empty
      expect(registration.xpath).to eq("/html")
      expect(registration.attribute_setters).to be_a(Hash)
      expect(registration.scripts).to eq(["a", "b", "c"])
      expect(registration.schema).to be_a(Stretched::Schema)
      expect(registration.schema.key).to eq("Listing")
      expect(registration.schema.data).not_to be_nil
      expect(registration.schema.data).not_to be_empty
    end
    
  end

  describe "::create" do
    it "creates a new registration object in the db and returns it" do
      registration = Stretched::ObjectAdapter.create(
        key: "test-1",
        user: @user,
        data: {"key" => "value", "schema" => "Listing"}
      )
      reg = Stretched::ObjectAdapter.find(@user, registration.key)
      expect(reg).to be_a(Stretched::ObjectAdapter)
      expect(reg.data).to eq({"key" => "value", "schema" => "Listing"})
    end
  end

  describe "::find" do
    it "finds an object that has previously been registered" do
      registration = Stretched::ObjectAdapter.new(
        user: @user,
        key: "test-1",
        data: {"key" => "value", "schema" => "Listing"}
      )
      registration.save

      reg = nil
      expect {
        reg = Stretched::ObjectAdapter.find(@user, registration.key)
      }.not_to raise_error

      expect(reg).to be_a(Stretched::ObjectAdapter)
      expect(reg.data).to eq({"key" => "value", "schema" => "Listing"})
    end
  end

end

