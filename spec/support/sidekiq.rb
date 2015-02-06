def clear_sidekiq
  Sidekiq.redis { |c| c.flushdb }
end
