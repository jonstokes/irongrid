module Notifier
  def notify(logline)
    domain_insert = @domain ? "[#{@domain}]": ""
    Rails.logger.info "#{self.class}(#{Thread.current.object_id})#{domain_insert}: #{logline}"
    puts "#{self.class}(#{Thread.current.object_id}): #{logline}" if Rails.env.test?
  end
end
