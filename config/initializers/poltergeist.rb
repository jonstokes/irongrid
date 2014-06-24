require "capybara"
require "capybara/poltergeist"
require "capybara/poltergeist/utility"

module Capybara::Poltergeist
  Client.class_eval do
    def start
      @pid = IO.popen(command.map(&:to_s)).pid
    end

    def stop
      if pid
        kill_phantomjs
      end
    end
  end
end
