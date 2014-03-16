require 'spec_helper'

describe DocReader do

  describe "#filter_target_text", no_es: true do
    before :each do
      @filters = [
        { "accept" => /Zip Code:\s+\d{5}/i },
        { "reject" => /Zip Code:/i }
      ]
      @doc_reader = DocReader.new({})
    end

    it "should correctly apply a sequence of filters to a target string" do
      target = "   Zip Code:  94708"
      @doc_reader.filter_target_text(@filters, target).should == "94708"
    end

    it "should return nil if the target text is nil" do
      @doc_reader.filter_target_text(@filters, nil).should be_nil
    end

    it "should return nil if the target text is not accepted" do
      target = "Zipcode: 94708"
      @doc_reader.filter_target_text(@filters, target).should be_nil
    end

    it "should return nil if the target text is rejected" do
      filters = [
        { "accept" => /\w+\s\w+/i },
        { "reject" => /Zip Code/i }
      ]
      target = "Zipcode: 94708"
      @doc_reader.filter_target_text(@filters, target).should be_nil
    end
  end
end
