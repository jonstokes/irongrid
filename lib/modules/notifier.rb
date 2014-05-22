module Notifier
  def self.included(klass)
    klass.extend(self)
  end

  def notify(logline)
    domain_insert = @domain ? "[#{@domain}]": ""
    Rails.logger.info "#{self.class}(#{Thread.current.object_id})#{domain_insert}: #{logline}"
  end
end
