class TestWorker < Bellbro::Worker
  sidekiq_options :queue => :crawls, :retry => false

  attr_reader :site, :page_queue

  def perform(opts={})
    puts "Starting job #{jid} with #{opts}..."
    sleep 30
    puts "Ending job #{jid}."
  end
end
