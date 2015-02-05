module Notifier
  def self.included(klass)
    klass.extend(self)
  end

  def notify(logline, opts={})
    domain_insert = @domain ? "[#{@domain}]": ""
    error_insert = (opts[:type] == :error) ? "##ERROR## " : ""
    complete_logline = "[#{self.class}](#{Thread.current.object_id})#{domain_insert}: #{error_insert}#{logline}"
    $log.info complete_logline
  end
end
