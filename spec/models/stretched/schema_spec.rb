require 'spec_helper'

describe Stretched::Registration do

  before :each do
    Stretched::Registration.with_redis { |conn| conn.flushdb }
    @user = "test@ironsights.com"
  end

  describe "#validate" do
    it "it validates an attribute/value pair against a JSON schema" do
      schema = Stretched::Schema.create_from_file(@user, "#{Rails.root}/spec/fixtures/stretched/registrations/schemas/listing.json").first
      expect(schema).to be_a(Stretched::Schema)
      expect(schema.key).to eq("Listing")

      expect(schema.validate("title", "This is a title")).to be_true
      expect(schema.validate("description", 1234)).to be_false

      expect(schema.validate("url", "http://retailer.com/")).to be_true
      expect(schema.validate("url", "retailer.com")).to be_false

      expect(schema.validate("valid", "true")).to be_false
      expect(schema.validate("valid", true)).to be_true

      expect(schema.validate("price_in_cents", "123")).to be_false
      expect(schema.validate("price_in_cents", 123)).to be_true

      expect(schema.validate("product_category1", "Firearms")).to be_false
      expect(schema.validate("product_category1", "Guns")).to be_true
    end
  end

end

