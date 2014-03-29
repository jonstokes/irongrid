require 'spec_helper'
require 'sidekiq/testing'
Sidekiq::Testing.fake!

class TrackWorker < CoreWorker
  include Trackable

  LOG_RECORD_SCHEMA = {
    links_created:    Integer,
    listings_updated: Integer,
    errors:           Array,
    status:           String
  }

  def jid
    "abc123"
  end
end

describe Trackable do
  before :each do
    @worker = TrackWorker.new
    Sidekiq::Worker.clear_all
  end

  describe "#track" do
    it "should properly initialize the log record" do
      @worker.track
      expect(@worker.record[:data][:links_created]).to eq(0)
      expect(@worker.record[:data][:listings_updated]).to eq(0)
      expect(@worker.record[:data][:errors]).to be_empty
      expect(@worker.record[:jid]).to eq("abc123")
    end
  end

  describe "#record_set" do
    it "sets a record" do
      @worker.track
      @worker.record_set(:status, "Update")
      expect(@worker.record[:data][:status]).to eq("Update")
    end
  end

  describe "#record_incr" do
    it "increments an integer record" do
      @worker.track
      5.times { @worker.record_incr(:links_created) }
      expect(@worker.record[:data][:links_created]).to eq(5)
    end
  end

  describe "#status_update" do
    it "generates a LogRecordWorker to update the status" do
      @worker.track(write_interval: 1)    # Generates LogRecordWorker
      @worker.status_update               # Generates LogRecordWorker
      @worker.record_incr(:links_created)
      @worker.status_update                # Generates LogRecordWorker
      expect(LogRecordWorker.jobs.count).to eq(3)
    end

    it "resets the record data after each status update with an outgoing LogRecordWorker" do
      @worker.track(write_interval: 1)
      5.times { @worker.record_incr(:links_created) }
      expect(@worker.record[:data][:links_created]).to eq(5)
      2.times { @worker.status_update }
      expect(@worker.record[:data][:links_created]).to eq(0)
    end
  end

  describe "#validate" do
    it "raises an error if an attribute is invalid" do
      @worker.track
      expect {
        @worker.send(:validate, {foo: "bar"})
      }.to raise_error(RuntimeError)
    end

    it "raises an error if a value is invalid" do
      @worker.track
      expect {
        @worker.send(:validate, {links_created: "bar"})
      }.to raise_error(RuntimeError)
    end
  end
end
