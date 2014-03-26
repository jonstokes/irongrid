require 'spec_helper'
require 'mocktra'
require 'sidekiq/testing'
Sidekiq::Testing.fake!

describe AvantlinkWorker do
  before :each do
    LinkData.delete_all
    create_site_from_repo "www.brownells.com"
  end

  describe "#perform" do
    describe "LinkData output" do
      it "should add new listings to the LinkData table with proper attributes" do
        Mocktra("datafeed.avantlink.com") do
          get '/download_feed.php' do
            File.open("#{Rails.root}/spec/fixtures/avantlink_feeds/test_feed.xml") do |file|
              file.read
            end
          end
        end

        AvantlinkWorker.new.perform(domain: "www.brownells.com")
        expect(LinkData.size).to eq(4)
        ld = LinkData.pop
        expect(ld.url).to match(/avantlink\.com/)
        expect(ld.page_attributes["digest"]).not_to be_nil
        expect(ld.page_is_valid?).to be_true
        expect(ld.page_not_found?).to be_false
      end

      it "should add modified listings to the LinkData table with proper attributes" do
        Mocktra("datafeed.avantlink.com") do
          get '/download_feed.php' do
            File.open("#{Rails.root}/spec/fixtures/avantlink_feeds/test_feed_update.xml") do |file|
              file.read
            end
          end
        end

        AvantlinkWorker.new.perform(domain: "www.brownells.com")
        expect(LinkData.size).to eq(4)
        ld = LinkData.pop
        expect(ld.url).to match(/avantlink\.com/)
        expect(ld.page_attributes["digest"]).not_to be_nil
        expect(ld.page_attributes["item_data"]["price_in_cents"]).to eq(109)
        expect(ld.page_is_valid?).to be_true
        expect(ld.page_not_found?).to be_false
      end

      it "should add removed listings to the LinkData table with the attributes" do
        Mocktra("datafeed.avantlink.com") do
          get '/download_feed.php' do
            File.open("#{Rails.root}/spec/fixtures/avantlink_feeds/test_feed_remove.xml") do |file|
              file.read
            end
          end
        end

        AvantlinkWorker.new.perform(domain: "www.brownells.com")
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
    end
  end
end
