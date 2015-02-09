class ReadSitesService < BaseService
  poll_interval 60
  track_with_schema jobs_started: Integer
  worker_class PopulateSessionQueueWorker
end
