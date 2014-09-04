module Stretched
  class RunSessionsWorker
    include Sidekiq::Worker
    extend Stretched::WorkerUtils

    sidekiq_options :queue => :stretched, :retry => true

    attr_accessor :timer
    attr_reader :session_q

    delegate :timed_out?, to: :timer

    def init(opts)
      opts.symbolize_keys!
      @debug = opts[:debug]
      @timer = Stretched::RateLimiter.new(opts[:timeout] || 1.hour.to_i)
      @session_q = SessionQueue.find_or_create(opts[:queue])
      return false unless @session_q.any?
      true
    end

    def perform(opts)
      return unless opts && init(opts)
      return unless i_am_alone_with_this_queue?(session_q.name) || (@debug = opts[:debug])

      outlog "Emptying session queue for #{session_q.name} with size #{session_q.size}..."
      while !timed_out? && (ssn = session_q.pop) do
        outlog "Popped session of size #{ssn.size} with definition #{ssn.definition_key}."
        RunSession.perform(stretched_session: ssn)
        outlog "Session for #{ssn.definition_key} finished!"
      end
      clean_up
      transition
    end

    def clean_up
      outlog "Worker for session queue #{session_q.name} finished. #{session_q.size} sessions left in queue.;"
    end

    def transition
      if @session_q.any?
        self.class.perform_async(queue: @session_q.name)
      end
    end

    def i_am_alone_with_this_queue?(q)
      self.class.jobs_with_session_queue(q).select { |j| jid != j[:jid] }.empty? &&
        self.class.workers_with_session_queue(q).select { |j| jid != j[:jid] }.empty?
    end

    def outlog(str)
      Rails.logger.info "[Stretched::RunSessionsWorker] #{str}"
    end

  end
end
