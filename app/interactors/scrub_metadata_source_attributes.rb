class ScrubMetadataSourceAttributes
  include Interactor

  def perform
    context[:title].scrubbed = scrub(title.raw)
    context[:title].autocomplete = title.raw
    context[:keywords].scrubbed = scrub(keywords.raw) if keywords.raw
  end

  def scrub(content)
    if category1 == "Optics"
      ProductDetails::Scrubber.scrub(content, :inches, :punctuation, :color)
    else
      ProductDetails::Scrubber.scrub_all(content)
    end
  end

  def normalize(content)
    
  end
end
