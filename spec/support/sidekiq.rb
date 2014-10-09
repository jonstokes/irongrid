def clear_sidekiq
  Sidekiq::Worker.clear_all
  %w(db_fast_high db_fast_low db_slow_high db_slow_low crawls crawl_images stretched).each do |q|
    Sidekiq::Queue.new(q).clear
  end
end
