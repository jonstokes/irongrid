require 'spec_helper'

describe SearchAlertQueues::AlertQueue do
  before :each do
    @match = "abc123"
    @q = SearchAlertQueues::AlertQueue.new(@match)
  end

  describe "#push" do
    it "pushes listing ids into redis in order based on timestamp" do
      @q.push(1)
      sleep 1
      @q.push(2)
      expect(@q.shift).to eq(1)
      expect(@q.shift).to eq(2)
    end

    it "keeps the queue size at the maximum" do
      31.times do |i|
        @q.push i
        sleep 1
      end
      expect(@q.size).to eq(30)
      expect(@q.shift).to eq(1)
    end
  end

  describe "#shift" do
    it "returns nil when empty" do
      expect(@q.shift).to be_nil
    end
  end
end
