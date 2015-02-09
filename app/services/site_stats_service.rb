class SiteStatsService < BaseService
  track_with_schema jobs_started: Integer
  poll_interval 3600
  worker_class SiteStatsWorker
end
