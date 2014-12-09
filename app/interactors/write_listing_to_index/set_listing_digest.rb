class SetListingDigest
  include Interactor

  def call
    context.listing.digest_attributes = context.site.digest_attributes
    context.listing.set_digest!
    context.fail!(status: :duplicate) if context.listing.digest_is_duplicate?
  end
end

