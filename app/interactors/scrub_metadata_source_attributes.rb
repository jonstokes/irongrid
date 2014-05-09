class ScrubMetaDataSourceAttributes
  include Interactor

  def setup
    context[:metadata_source_attrs] = {}
  end

  def peform
    %w(title keywords).each do |attr|
      next unless content = raw_listing[attr]
      metadata_source_attrs[attr] = {
        attr.to_sym   => content,
        :autocomplete => content,
        :scrubbed     => scrub(content),
      }
    end
  end

  def scrub(content)
    if category1 == "Optics"
      ProductDetails::Scrubber.scrub(content, :inches, :punctuation, :color)
    else
      ProductDetails::Scrubber.scrub_all(content)
    end
  end
end
