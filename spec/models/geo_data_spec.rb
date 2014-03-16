# == Schema Information
#
# Table name: geo_data
#
#  id         :integer          not null, primary key
#  key        :string(255)
#  data       :hstore
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require 'spec_helper'

describe GeoData do
  before :all do
    @key = "1213 Newning Ave., Austin TX"
  end

  describe "self.put", no_es: true do
    it "should write a new GeoData object to the table" do
      GeoData.put(@key).should_not be_nil
      GeoData.count.should == 1
      loc = GeoData.first
      loc.latitude.should == "30.25054399999999"
      loc.longitude.should == "-97.74310799999999"
    end

    it "should return the object if the key already exists" do
      loc1 = GeoData.put(@key)
      loc1.should_not be_nil
      loc2 = GeoData.put(@key)
      GeoData.count.should == 1
      loc2.should_not be_nil
      loc1.id.should == loc2.id
    end

    it "should return a copy of the new object" do
      loc = GeoData.put(@key)
      loc.is_a?(GeoData).should be_true
      loc.id.should_not be_nil
    end

    it "should not be case sensitive with keys" do
      GeoData.put(@key.downcase).id.should == GeoData.put(@key.upcase).id
      GeoData.count.should == 1
    end

    it "should raise an error if the key is nil" do
      expect { GeoData.put(nil) }.to raise_error
    end

    it "should raise an error if the key is empty" do
      expect { GeoData.put(" ") }.to raise_error
    end
  end

  describe "fetch_data", no_es: true do
    it "should populate the GeoData object's data field with the geolocation data" do
      loc = GeoData.create(:key => @key)
      loc.fetch_data
      loc.city.should == "Austin"
      loc.state.should == "Texas"
      loc.state_code.should == "TX"
      loc.postal_code.should == "78704"
      loc.latitude.should == 30.25054399999999
      loc.longitude.should == -97.74310799999999
    end
  end
end
