$log = Rails.env.production? ? Logglier.new("https://logs-01.loggly.com/inputs/fb269edb-34ac-4ada-ae19-af0c0903b87b/tag/ruby/") : Rails.logger
