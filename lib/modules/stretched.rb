module Stretched
  def self.session_queue_is_being_read?(domain)
    SessionQueue.new(domain).any? || RunSessionsWorker.jobs_in_flight_with_session_queue(domain).any?
  end
end
