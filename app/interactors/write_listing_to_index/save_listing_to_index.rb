class WriteListingToIndex
  class SaveListingToIndex
    include Interactor
    include Bellbro::Ringable

    def call
      context.listing.save
    rescue Elasticsearch::Transport::Transport::Errors::InternalServerError => e
      Airbrake.notify(e)
      gong "Listing #{context.listing.url.page} raised #{e.message}"
    end
  end
end

