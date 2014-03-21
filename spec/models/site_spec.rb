require 'spec_helper'

describe Site do

  # NOTE: Major changes:
  # 1. This now exists entirely in redis as "www.domain.com" => "JSON hash" , and is removed from postgres.
  # 2. There is no service_options hash. There are only seed_links, some of which
  #    have a PAGENUM and some don't. The CreateLinksWorker can differentiate between the two.

  describe "#initialize" do
    it "should load its JSON data from local repo when source: is :local" do
      pending "Example"
    end

    it "should load its JSON data from github when source: is :github" do
      pending "Example"
    end

    it "should load its JSON data from redis when source: is :redis" do
      pending "Example"
    end
  end
end
