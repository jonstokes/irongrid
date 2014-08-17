require 'spec_helper'

describe Stretched::Script do

  before :each do
    Stretched::Registration.with_redis { |conn| conn.flushdb }
    @source_file = "#{Rails.root}/spec/fixtures/stretched/registrations/scripts/product_page.rb"
    @source = File.open(@source_file) { |f| f.read }
    @script = Stretched::Script.new(
        key: "globals/product_page",
        data: @source
      )
  end

  describe "#initialize" do
    it "creates a new script object" do
      expect(@script).to be_a(Stretched::Script)
      expect(@script.key).to eq("globals/product_page")
      expect(@script.data).to include("Stretched::Script.define")
    end
  end

  describe "#register" do
    it "evals the script's source and registers a runner" do
      expect { @script.register }.not_to raise_error
      expect(Stretched::Script.registry).not_to be_empty
      runner = Stretched::Script.registry[@script.key]
      expect(runner).to be_a(Stretched::ScriptRunner)
    end
  end

  describe "::create_from_file" do
    it "creates a new script object from a file and returns it" do
      script = Stretched::Script.create_from_file(@source_file).first
      reg = Stretched::Script.find(script.key)
      expect(reg).to be_a(Stretched::Script)
      expect(reg.key).to eq("globals/product_page")
      expect(reg.data).to include("Stretched::Script.define")
    end
  end

  describe "::create" do
    it "creates a new script object in the db and returns it" do
      script = Stretched::Script.create(
          key: "globals/product_page",
          data: @source
        )
      reg = Stretched::Script.find(@script.key)
      expect(reg).to be_a(Stretched::Script)
      expect(@script.data).to include("Stretched::Script.define")
    end
  end

  describe "::find" do
    it "finds an object that has previously been registered" do
      script = Stretched::Script.create(
          key: "globals/product_page",
          data: @source
        )
      reg = nil
      expect {
        reg = Stretched::Script.find(script.key)
      }.not_to raise_error

      expect(reg).to be_a(Stretched::Script)
      expect(@script.data).to include("Stretched::Script.define")
    end
  end

  describe "::runner" do
    it "finds an object that has previously been registered and returns a runner for it" do
      script = Stretched::Script.create(
          key: "globals/product_page",
          data: @source
        )
      runner = Stretched::Script.runner(script.key)
      expect(Stretched::Script.registry).not_to be_empty
      expect(runner).to be_a(Stretched::ScriptRunner)
    end

  end

end

