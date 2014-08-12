require 'spec_helper'

describe Stretched::ScriptRunner do

  before :each do
    Stretched::Registration.with_redis { |conn| conn.flushdb }
    @source = File.open("#{Rails.root}/spec/fixtures/stretched/registrations/scripts/product_page.rb") { |f| f.read }
  end

  describe "#set_context" do
    it "creates a new script object" do
      script = Stretched::Script.create(
        key: "product_page",
        data: @source
      )
      runner = Stretched::Script.runner(script.key)
      instance = {}
      runner.set_context(price: 100)
      runner.attributes.each do |attribute_name, value|
        result = value.is_a?(Proc) ? value.call(instance) : value
        instance[attribute_name] = result
      end

      expect(instance[:title]).to eq("This is the title")
      expect(instance[:description]).to eq("This is the description")
      expect(instance[:price]).to eq(150)
      expect(instance[:sale_price]).to eq(140)
    end
  end
end

