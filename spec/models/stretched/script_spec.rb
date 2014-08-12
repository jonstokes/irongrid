require 'spec_helper'

describe Stretched::Script do

  before :each do
    Stretched::Registration.with_redis { |conn| conn.flushdb }
    @source = File.open("#{Rails.root}/spec/fixtures/stretched/registrations/scripts/product_page.rb") { |f| f.read }
  end

  describe "#initialize" do
    it "creates a new script object" do
      script = Stretched::Script.new(
        key: "product_page",
        data: @source
      )
      expect(script).to be_a(Stretched::Script)
      expect(script.key).to eq("product_page")
      expect(script.data).to include("Stretched::Script.define")
    end
  end

  describe "::create" do
    it "creates a new script object in the db and returns it" do
      script = Stretched::Script.create(
        key: "product_page",
        data: @source
      )

      reg = Stretched::Script.find(script.key)
      expect(reg).to be_a(Stretched::Script)
      expect(script.data).to include("Stretched::Script.define")
    end
  end

  describe "::find" do
    it "finds an object that has previously been registered" do
      script = Stretched::Script.create(
        key: "product_page",
        data: @source
      )

      reg = nil
      expect {
        reg = Stretched::Script.find(script.key)
      }.not_to raise_error

      expect(reg).to be_a(Stretched::Script)
      expect(script.data).to include("Stretched::Script.define")
    end
  end

end

