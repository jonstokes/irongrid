require "capybara"
require "capybara/poltergeist"
require "capybara/poltergeist/utility"

module Capybara::Poltergeist
  Client.class_eval do
    def start
      @pid = Process.spawn(*command.map(&:to_s), pgroup: true)
      ObjectSpace.define_finalizer(self, self.class.process_killer(@pid))
    end

    def stop
      if pid
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

  WebSocketServer.class_eval do
    def accept
      Rails.logger.info "### Called WebSocketServer#accept for object #{self.object_id}: #{caller}"
      @socket   = server.accept
      @messages = []

      @driver = ::WebSocket::Driver.server(self)
      @driver.on(:connect) { |event| @driver.start }
      @driver.on(:message) { |event| @messages << event.data }
    end

    def close
      Rails.logger.info "### Called WebSocketServer#close for object #{self.object_id}: #{caller}"
      [server, socket].compact.each(&:close)
    end
  end
end
