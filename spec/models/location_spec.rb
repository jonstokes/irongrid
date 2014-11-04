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

describe Location do
  before :all do
    @key = "1213 Newning Ave., Austin TX"
  end

  describe "self.put", no_es: true do
    it "should write a new Location object to the table" do
      Location.put(@key).should_not be_nil
      Location.count.should == 1
      loc = Location.first
      loc.latitude.should == 30.25054399999999
      loc.longitude.should == -97.74310799999999
    end

    it "should return the object if the key already exists" do
      loc1 = Location.put(@key)
      loc1.should_not be_nil
      loc2 = Location.put(@key)
      Location.count.should == 1
      loc2.should_not be_nil
      loc1.id.should == loc2.id
    end

    it "should return a copy of the new object" do
      loc = Location.put(@key)
      loc.is_a?(Location).should be_true
      loc.id.should_not be_nil
    end

    it "should not be case sensitive with keys" do
      Location.put(@key.downcase).id.should == Location.put(@key.upcase).id
      Location.count.should == 1
    end

    it "should raise an error if the key is nil" do
      expect { Location.put(nil) }.to raise_error
    end

    it "should raise an error if the key is empty" do
      expect { Location.put(" ") }.to raise_error
    end
  end

  describe "fetch_data", no_es: true do
    it "should populate the Location object's data field with the geolocation data" do
      loc = Location.create(:key => @key)
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
