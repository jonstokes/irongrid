def clear_sidekiq
  Sidekiq::Worker.clear_all
  %w(fast_db slow_db crawls crawl_images stretched).each do |q|
    Sidekiq::Queue.new(q).clear
  end
end
