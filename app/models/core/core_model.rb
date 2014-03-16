class CoreModel
  include Retryable
  include Notifier
  include ConnectionWrapper
end

