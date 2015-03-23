class WriteListingToIndex
  class SaveListingToIndex
    include Interactor
    include Shout

    def call
      context.listing.save
    rescue Elasticsearch::Transport::Transport::Errors::InternalServerError => e
      Airbrake.notify(e)
      error "Listing #{context.listing.url.page} raised #{e.message}"
    end
  end
end

