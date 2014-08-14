module Stretched
  class RunSessionsWorker

    sidekiq_options :queue => :crawls, :retry => true

    attr_accessor :timer if Rails.env.test?

    delegate :timed_out?, to: :timer

    def init(opts)
      opts.symbolize_keys!

      @timer = Stretched::RateLimiter.new(opts[:timeout] || 1.hour.to_i)
      @session_q = SessionQueue.new(opts[:session_queue_name])
      return false unless @session_q.any?

      true
    end

    def perform(opts)
      return unless opts && init(opts)
      return unless i_am_alone_with_this_queue?(@session_q.key) || (@debug = opts[:debug])

      notify "Emptying session queue for #{session_q.key}..."
      while !timed_out? && (ssn = @session_q.pop) do
        outlog "Popped session with definition #{ssn.session_definition.key}"
        result = RunSession.perform(stretched_session: ssn)
        object_q.add result.json_objects
        outlog "Session #{ssn.key} finished! Timeout is #{@timeout}"
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

    def i_am_alone_with_this_queue?

    def outlog(str)
      return unless @debug
      notify "### #{str}"
    end

  end
end
