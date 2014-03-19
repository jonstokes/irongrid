class ImageSet < LinkSet
  attr_reader :domain, :set_name

  def initialize(opts)
    raise "Domain required!" unless @domain = opts[:domain]
    @set_name = "#imageset--#{domain}"
  end

  private

  def is_valid_url?(key)
    !!URI.parse(key).host rescue nil
  end
end
