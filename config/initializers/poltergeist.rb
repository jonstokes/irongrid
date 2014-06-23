require "capybara"
require "capybara/poltergeist"
require "capybara/poltergeist/utility"

module Capybara::Poltergeist
  Client.class_eval do
    def start
      @read_io = IO.popen(command.map(&:to_s))
      @pid = @read_io.pid
      @out_thread = Thread.new {
        while !@read_io.closed? && !@read_io.eof? && data = @read_io.readpartial(1024)
          @phantomjs_logger.write(data)
        end
      }
    end

    def stop
      if pid
        kill_phantomjs
        @out_thread.kill if @out_thread
        @read_io.close if @read_io && !@read_io.closed?
      end
    end
  end
end
