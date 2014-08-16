require 'spec_helper'
require 'mocktra'
require 'sidekiq/testing'

describe Stretched::RunSessionsWorker do
  before :each do
    Sidekiq::Testing.fake!
    @worker = ProductFeedWorker.new
    CDN.clear!
    Sidekiq::Worker.clear_all
  end

  describe "#perform" do
  end
end
