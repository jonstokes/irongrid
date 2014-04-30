require 'spec_helper'

describe DocReader do

  describe "#find_by_xpath", no_es: true do
    before :each do
      @args = {
        'xpath' => '//link'
      }
      @link = "http://www.retailer.com/product/1"
      xml = "<xml><link>#{@link}</link></xml>"
      @doc = Nokogiri::XML.parse(xml)
      @url = "http://www.retailer.com/"
    end

    it "correctly locates a link at an xpath" do
      @doc_reader = DocReader.new(doc: @doc, url: @url)
      expect(@doc_reader.find_by_xpath(@args)).to eq(@link)
    end

    it "correctly extracts text via regexp" do
      regexp = /retailer/
      @args.merge!('regexp' => regexp)
      @doc_reader = DocReader.new(doc: @doc, url: @url)
      expect(@doc_reader.find_by_xpath(@args)).to eq(@link[regexp])
    end
  end

  describe "Meta tags" do
    before :all do
      html = File.open("#{Rails.root}/spec/fixtures/web_pages/www--retailer--com/1.html") {|f| f.read}
      doc = Nokogiri::HTML.parse(html)
      @doc_reader = DocReader.new(url: "http://www.retailer.com/1.html", doc: doc)
      @image = "http://cdn.retailer.com/image1.jpg"
    end

    it "correctly extracts a meta tag name attribute" do
      expect(@doc_reader.meta_name('value' => 'mc-category')).to eq("Ammo")
    end

    it "correctly extracts a meta tag property attribute" do
      expect(@doc_reader.meta_property('value' => 'og:image')).to eq(@image)
    end

    it "correctly returns a property that's marked up with schema.org markup" do
      expect(@doc_reader.schema_name).to eq("Citadel 1911")
    end

    it "correctly returns a meta tag attribute using method_missing" do
      expect(@doc_reader.meta_keywords).to eq("CITADEL 1911 COMPACT .45ACP")
    end

    it "correctly returns a meta og tag attribute using method_missing" do
      expect(@doc_reader.meta_og_image).to eq(@image)
    end
  end

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
