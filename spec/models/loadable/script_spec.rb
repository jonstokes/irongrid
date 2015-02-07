require 'spec_helper'

describe Loadable::Script do

  before :each do
    Loadable::Script.with_connection { |conn| conn.flushdb }
    @source_file = "#{Rails.root}/spec/fixtures/loadables/www--budsgunshop--com.rb"
    @source = File.open(@source_file) { |f| f.read }
    @script = Loadable::Script.new(
        key: "www.budsgunshop.com/shipping",
        data: @source
      )
  end

  describe "#initialize" do
    it "creates a new script object" do
      expect(@script).to be_a(Loadable::Script)
      expect(@script.key).to eq("www.budsgunshop.com/shipping")
      expect(@script.data).to include("Loadable::Script.define")
    end
  end

  describe "::create_from_file" do
    it "creates a new script object from a file and returns it" do
      script = Loadable::Script.create_from_file(@source_file).first
      reg = Loadable::Script.find(script.key)
      expect(reg).to be_a(Loadable::Script)
      expect(reg.key).to eq("www.budsgunshop.com/shipping")
      expect(reg.data).to include("Loadable::Script.define")
    end
  end

  describe "::create" do
    it "creates a new script object in the db and returns it" do
      script = Loadable::Script.create(
          key: "www.budsgunshop.com/shipping",
          data: @source
        )
      reg = Loadable::Script.find(@script.key)
      expect(reg).to be_a(Loadable::Script)
      expect(@script.data).to include("Loadable::Script.define")
    end
  end

  describe "::find" do
    it "finds an object that has previously been registered" do
      script = Loadable::Script.create(
          key: "www.budsgunshop.com/shipping",
          data: @source
        )
      reg = nil
      expect {
        reg = Loadable::Script.find(script.key)
      }.not_to raise_error

      expect(reg).to be_a(Loadable::Script)
      expect(@script.data).to include("Loadable::Script.define")
    end
  end

  describe "::runner" do
    it "finds an object that has previously been registered and returns a runner for it" do
      script = Loadable::Script.create(
          key: "www.budsgunshop.com/shipping",
          data: @source
        )
      runner = Loadable::Script.runner(script.key)
      expect(runner).to be_a(Loadable::ScriptRunner)
    end

  end

end

