class RefreshLinksService < BaseService
  poll_interval 120
  track_with_schema jobs_started: Integer
  worker_class RefreshLinksWorker
end
