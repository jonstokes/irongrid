require 'spec_helper'

describe Stretched::Script do

  before :each do
    Stretched::Registration.with_redis { |conn| conn.flushdb }
    source = File.open("#{Rails.root}/spec/fixtures/stretched/registrations/scripts/product_page.rb") { |f| f.read }
    @script = Stretched::Script.new(
        key: "globals/product_page",
        data: source
      )
  end

  describe "#initialize" do
    it "creates a new script object" do
      expect(@script).to be_a(Stretched::Script)
      expect(@script.key).to eq("globals/product_page")
      expect(@script.data).to include("Stretched::Script.define")
    end
  end

  describe "#register_runner" do
    it "evals the script's source and registers a runner" do
      expect { @script.register_runner }.not_to raise_error
      expect(Stretched::Script.registry).not_to be_empty
      runner = Stretched::Script.registry[@script.key]
      expect(runner).to be_a(Stretched::ScriptRunner)
    end
  end

  describe "::load_from_file" do
    it "creates a new script object from a file and returns it" do
      reg = Stretched::Script.find(@script.key)
      expect(reg).to be_a(Stretched::Script)
      expect(@script.data).to include("Stretched::Script.define")
    end
  end


  describe "::create" do
    it "creates a new script object in the db and returns it" do
      reg = Stretched::Script.find(@script.key)
      expect(reg).to be_a(Stretched::Script)
      expect(@script.data).to include("Stretched::Script.define")
    end
  end

  describe "::find" do
    it "finds an object that has previously been registered" do
      reg = nil
      expect {
        reg = Stretched::Script.find(@script.key)
      }.not_to raise_error

      expect(reg).to be_a(Stretched::Script)
      expect(@script.data).to include("Stretched::Script.define")
    end
  end

  describe "::runner" do
    it "finds an object that has previously been registered and returns a runner for it" do
      runner = Stretched::Script.runner(@script.key)
      expect(Stretched::Script.registry).not_to be_empty
      expect(runner).to be_a(Stretched::ScriptRunner)
    end

  end

end

