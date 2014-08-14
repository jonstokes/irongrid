module Stretched
  class RunSessionsWorker
    include Sidekiq::Worker

    sidekiq_options :queue => :crawls, :retry => true

    attr_accessor :timer if Rails.env.test?

    delegate :timed_out?, to: :timer

    def init(opts)
      opts.symbolize_keys!

      @timer = Stretched::RateLimiter.new(opts[:timeout] || 1.hour.to_i)
      @session_q = SessionQueue.find_or_create(opts[:session_queue_name])
      return false unless @session_q.any?

      true
    end

    def perform(opts)
      return unless opts && init(opts)
      return unless i_am_alone_with_this_queue?(@session_q.key) || (@debug = opts[:debug])

      notify "Emptying session queue for #{session_q.key}..."
      while !timed_out? && (ssn = @session_q.pop) do
        outlog "Popped session of size #{ssn.size} with definition #{ssn.definition_key}."
        RunSession.perform(stretched_session: ssn)
        outlog "Session for #{ssn.definition_key} finished! Timeout is #{@timeout}"
      end
      clean_up
      transition
    end

    def clean_up
      # Log out the end of the session
    end

    def transition
      if @session_q.any?
        self.class.perform_async(domain: domain)
      end
    end

    def i_am_alone_with_this_queue?(queue_name)
      # FIXME
      true
    end

    def outlog(str)
      return unless @debug
      notify "### #{str}"
    end

  end
end
