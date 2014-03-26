require 'spec_helper'

describe AvantlinkWorker do
  describe "#perform" do
    before :each do
      LinkData.delete_all
      create_site_from_repo "www.brownells.com"
      @worker = AvantlinkWorker.new
    end

    describe "LinkData output" do
      it "should add new listings to the LinkData table with proper attributes" do
        worker = AvantlinkWorker.new
        worker.perform(domain: "www.brownells.com", filename: "spec/fixtures/avantlink_feeds/test_feed.xml")
        expect(LinkData.size).to eq(4)
        ld = LinkData.pop
        expect(ld.url).to match(/avantlink\.com/)
        expect(ld.page_attributes["digest"]).not_to be_nil
        expect(ld.page_is_valid?).to be_true
        expect(ld.page_not_found?).to be_false
      end

      it "should add modified listings to the LinkData table with proper attributes" do
        worker = AvantlinkWorker.new
        worker.perform(domain: "www.brownells.com", filename: "spec/fixtures/avantlink_feeds/test_feed_update.xml")
        expect(LinkData.size).to eq(4)
        ld = LinkData.pop
        expect(ld.url).to match(/avantlink\.com/)
        expect(ld.page_attributes["digest"]).not_to be_nil
        expect(ld.page_attributes["item_data"]["price_in_cents"]).to eq(109)
        expect(ld.page_is_valid?).to be_true
        expect(ld.page_not_found?).to be_false
      end

      it "should add removed listings to the LinkData table with the attributes" do
        worker = AvantlinkWorker.new
        worker.perform(domain: "www.brownells.com", filename: "spec/fixtures/avantlink_feeds/test_feed_remove.xml")
        expect(LinkData.size).to eq(4)
        ld = LinkData.pop
        expect(ld.url).to match(/avantlink\.com/)
        expect(ld.page_attributes).to be_nil
        expect(ld.page_is_valid?).to be_false
        expect(ld.page_not_found?).to be_true
      end
    end

    describe "internals" do
      it "should populate the db from a local file" do
        worker = AvantlinkWorker.new
        worker.perform(domain: "www.brownells.com", filename: "spec/fixtures/avantlink_feeds/test_feed.xml")
        LinkData.size.should == 4
        #JobRecord.first.pages_created.should == 4
      end

      it "should populate the db from a feed url" do
        service_options = {
          "feeds" => [
            {
              "url" => populate_link(File.join(Rails.root, "spec/fixtures/avantlink_feeds/test_feed.xml"), "test-feed"),
              "product_list_xpath" => '//Products/Product',
              "product_link_xpath" => '//Buy_Link'
            }
          ]
        }
        site = Site.new(domain: "www.brownells.com")
        site.update_attribute(:service_options, service_options)
        worker = AvantlinkWorker.new
        worker.perform(domain: "www.brownells.com")
        LinkData.size.should == 4
        #JobRecord.first.pages_created.should == 4
      end
    end
  end
end
