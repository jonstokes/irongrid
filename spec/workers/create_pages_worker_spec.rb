require 'spec_helper'

describe CreatePagesWorker do
  it "sends a 404'd listing ID to the DeleteDeactivateListingsQueue" do
    # if it pops a link from the link_set where conn.get("http://foo.com/") == "id: 1223"
    #   and the link 404's then it should push {id: "1234", action: "delete"} to the DDQ
    #   and it should conn.rem("http://foo.com/")
    #
  end
end
