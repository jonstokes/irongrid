require 'spec_helper'

describe AvantlinkWorker do
  describe "#perform" do
    before :each do
      @worker = AvantlinkWorker.new
      @pq = PageQueue.new
    end

    it "should add new listings to the PageQueue with proper :format" do
      pending "Example"
      # PQ << { url: url, source: xml, format: :xml }
    end

    it "should add modified listings to the PageQueue with proper :format and :id" do
      pending "Example"
      # PQ << { url: url, source: xml, format: :xml, id: :lookup }

      # @worker.perform(domain: "www.brownells.com", filename: "spec/fixtures/test_feed.xml")
      # write_page_queue_to_database
      worker = AffiliatesWorker.new
      worker.perform(domain: "www.brownells.com", filename: "spec/fixtures/test_feed_update.xml")
      @pq.size.should == 10
      @pq.pop[:id].should == :lookup
      @page.pop[:source].should_not be_nil
    end

    it "should add removed listings to the PageQueue with the proper :id and :source" do
      pending "Example"
      # if status == "REMOVED"
      #   PQ { url: url, source: nil, id: :lookup }
      worker = AffiliatesWorker.new
      worker.perform(domain: "www.brownells.com", filename: "spec/fixtures/test_feed_remove.xml")
      @pq.size.should == 10
      page = @pq.pop
      page[:id].should == :lookup
      page[:source].should be_nil
    end

    it "should populate the db from a local file" do
      worker = AffiliatesWorker.new
      worker.perform(domain: "www.brownells.com", filename: "spec/fixtures/test_feed.xml")
      PageQueue.new("www.brownells.com").size.should == 4
      JobRecord.first.pages_created.should == 4
    end

    it "should populate the db from a feed url" do
      service_options = {
        "feeds" => [
          {
            "url" => populate_link(File.join(Rails.root, "spec/fixtures/test_feed.xml"), "test-feed"),
            "product_list_xpath" => '//Products/Product',
            "product_link_xpath" => '//Buy_Link'
          }
        ]
      }
      #Site.find_by_domain("www.brownells.com").update_attribute(:service_options, service_options)
      worker = AffiliatesWorker.new
      worker.perform(domain: "www.brownells.com")
      PageQueue.new("www.brownells.com").size.should == 4
      JobRecord.first.pages_created.should == 4
    end

    it "should modify listings that are marked as modified" do
    end

    it "should delete listings that are marked as deleted" do
      worker = AffiliatesWorker.new
      worker.perform(domain: "www.brownells.com", filename: "spec/fixtures/test_feed.xml")
      write_page_queue_to_database
      worker = AffiliatesWorker.new
      worker.perform(domain: "www.brownells.com", filename: "spec/fixtures/test_feed_remove.xml")
      JobRecord.last.listings_deleted.should == 4
    end
  end

  end
end
