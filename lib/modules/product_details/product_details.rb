module ProductDetails
  def self.renormalize_all(text)
    return unless text.present?
    str = text.dup
    str = Caliber.parse(str)[:text]
    str = Manufacturer.parse(str)[:text]
    str
  end
end
