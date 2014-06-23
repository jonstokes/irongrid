require "capybara"
require "capybara/poltergeist"
require "capybara/poltergeist/utility"

module Capybara::Poltergeist
  Client.class_eval do
    def redirect_stdout
      prev = STDOUT.dup
      prev.autoclose = false
      STDOUT.reopen(@write_io)
      yield
    ensure
      STDOUT.reopen(prev)
      prev.close unless prev.closed?
    end
  end
end
