require "capybara"
require "capybara/poltergeist"
require "capybara/poltergeist/utility"

module Capybara::Poltergeist
  Client.class_eval do
    def start
      puts "Entering popen..."
      IO.popen(command.map(&:to_s)) do |pipe|
        @read_io = pipe
        puts "  Spawning out_thread..."
        @out_thread = Thread.new {
          while !@read_io.closed? && !@read_io.eof? && data = @read_io.readpartial(1024)
            @phantomjs_logger.write(data)
          end
        }
        puts "  Out_thread spawned"
        @pid = pipe.pid
      end
      puts "Exited popen"
    end

    def stop
      puts "Stopping..."
      if pid
        kill_phantomjs
        @out_thread.kill if @out_thread
        @read_io.close if @read_io && !@read_io.closed?
      end
      puts "Stopped!"
    end
  end
end
