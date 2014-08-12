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
      pending "Example"
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
      expect(JSON.parse(value)).to eq({ "key" => "value" })
    end
  end
end

