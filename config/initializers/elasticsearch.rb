# Monkey patch to make this work better with typhoeus

module Elasticsearch
  module Transport
    module Transport
      module HTTP

        # The default transport implementation, using the [_Faraday_](https://rubygems.org/gems/faraday)
        # library for abstracting the HTTP client.
        #
        # @see Transport::Base
        #
        class Faraday
          include Elasticsearch::Transport::Transport::Base

          # Performs the request by invoking {Transport::Base#perform_request} with a block.
          #
          # @return [Response]
          # @see    Transport::Base#perform_request
          #
          def perform_request(method, path, params={}, body=nil)
            super do |connection, url|
              response = connection.connection.run_request \
                method.downcase.to_sym,
                url,
                ( body ? __convert_to_json(body) : nil ),
                {}
              response.on_complete do
                Elasticsearch::Transport::Transport::Response.new response.status, response.body, response.headers
              end
            end
          end
        end
      end
    end
  end
end
