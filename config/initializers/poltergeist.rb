require "capybara"
require "capybara/poltergeist"
require "capybara/poltergeist/utility"

module Capybara::Poltergeist
  Client.class_eval do
    def start
      @pid = Process.spawn(*command.map(&:to_s), pgroup: true)
      ObjectSpace.define_finalizer(self, self.class.process_killer(@pid))
      Rails.logger.info "### Started PID #{@pid} [#{phantomjs_count}]. Trace: #{caller}"
    end

    def phantomjs_count
      `ps aux | grep phantomjs | wc -l`.strip
    end

    def stop
      if pid
        Rails.logger.info "### Stopped PID #{pid} [#{phantomjs_count}]. Trace: #{caller}"
        kill_phantomjs
        ObjectSpace.undefine_finalizer(self)
      end
    end
  end

  Browser.class_eval do
    def find(method, selector)
      tries = 3
      result = command('find', method, selector)
      result['ids'].map { |id| [result['page_id'], id] }
    rescue NoMethodError
      restart
      retry unless (tries -= 1).zero?
    end
  end
end
