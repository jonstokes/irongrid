class ExtractListingWithRubyAdapter
  include Interactor

  def setup
    context[:adapter_rb] = (adapter_type == :feed) ? site.feed_adapter_ruby : site.page_adapter_ruby
  end

  def perform
    GLOBAL_ADAPTER.each { |source| instance_eval source }
    instance_eval adapter_rb if adapter_rb
  end

  def set(attribute, &block)
    value = yield
#    return unless Schema::Validator.validate(
#      schema: schema,
#      attribute: attribute,
#      value: value
#    )
    context[attribute.to_sym] = value
  end
end


