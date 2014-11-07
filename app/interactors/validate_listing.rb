class ValidateListing
  include Interactor

  def call
    context.fail!(status: :not_found) if context.listing.auction? && context.listing.auction_ended?

  end
end
