require 'spec_helper'

describe RefreshLinksWorker do
  it "adds a link and a database id to the LinkSet for a stale listing" do
    # LinkSet("www.foo.com") << { url: "http://www.foo.com/1", id: "1234" }
  end
end
