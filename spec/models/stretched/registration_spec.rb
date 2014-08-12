require 'spec_helper'

describe Stretched::Registration do
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
end

