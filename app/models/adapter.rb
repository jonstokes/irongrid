class Adapter

  attr_reader :data

  delegate :[], :[]=, :each, :keys, to: :data

  def initialize(data)
    @data = data
  end

  def validation
    @data['validation']
  end

  def digest_attributes(defaults)
    return defaults unless attrs = @data["digest_attributes"]
    return attrs unless attrs.include?("defaults")
    attrs = defaults + attrs # order matters here, so no +=
    attrs.delete("defaults")
    attrs
  end

  def method_missing(method_id, *arguments, &block)
    @respond_to ||= Set.new
    if method_id.to_s["default_"] && @data['seller_defaults']
      @respond_to << method_id
      default = "#{method_id}".split("default_").last
      @data['seller_defaults'][default]
    else
      super
    end
  end

  def respond_to?(method_id, include_private = false)
    @respond_to && @respond_to.include?(method_id) ? true : super
  end
end
