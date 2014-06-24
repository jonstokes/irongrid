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
end
