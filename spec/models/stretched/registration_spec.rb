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
        :$key => "test-1",
        :data => {
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
      expect(JSON.parse(value)).to eq({ "key" => "value" })
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

