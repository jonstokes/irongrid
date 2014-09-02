module Stretched
  module Settings

    def self.configure
      $stretched_configuration ||= Hashie::Mash.new
      yield $stretched_configuration
    end

    def self.user
      $stretched_configuration.user
    end
  end
end
