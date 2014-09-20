require 'spec_helper'

describe Stretched::User do
  describe "#save" do
    it "creates a new user in redis" do
      Stretched::User.new("jon").save
      expect(Stretched::User.has_user?("jon")).to be_true
    end
  end

  describe "#destroy" do
    it "deletes a user from redis" do
      user = Stretched::User.new("jon")
      user.save
      expect(Stretched::User.has_user?("jon")).to be_true
      user.destroy
      expect(Stretched::User.has_user?("jon")).to be_false
    end
  end

  describe "::each" do
    it "iterates through the entire user set" do
      names = %w(jon marvin stokes)
      names.each { |name| Stretched::User.new(name).save }
      Stretched::User.each do |user|
        expect(names.include?(user.name)).to be_true
      end
    end
  end

end
