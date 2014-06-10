module Notifier
  def self.included(klass)
    klass.extend(self)
  end

  def notify(logline, opts={})
    domain_insert = @domain ? "[#{@domain}]": ""
    error_insert = (opts[:type] == :error) ? "##ERROR## " : ""
    Rails.logger.info "#{self.class}(#{Thread.current.object_id})#{domain_insert}: #{error_insert}#{logline}"
  end
end
