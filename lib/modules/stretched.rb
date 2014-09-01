module Stretched
  def self.queue_is_being_read?(domain)
    SessionQueue.new(domain).any? || RunSessionsWorker.jobs_in_flight_for_queue(domain).any?
  end
end
