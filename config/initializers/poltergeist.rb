require "capybara"
require "capybara/poltergeist"
require "capybara/poltergeist/utility"

module Capybara::Poltergeist
  Client.class_eval do
    def start
      @io = IO.popen(command.map(&:to_s))
      close_io
      @pid = @io.pid
    end

    def stop
      if pid
        kill_phantomjs
      end
    end

    def close_io
      begin
        @io.close unless @io.closed?
      rescue IOError
      end
    end
  end
end
