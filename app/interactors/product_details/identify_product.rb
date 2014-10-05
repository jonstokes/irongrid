module ProductDetails
  class IdentifyProduct < CoreModel
    include Interactor

    def perform
      # Use product database to populate product metadata where possible
      # Which product db will depend on which index I'm writing to (?)
    end

  end
end
