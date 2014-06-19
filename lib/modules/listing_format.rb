module ListingFormat
  DEFAULT_LISTING_TIMEZONE = "Central Time (US & Canada)"

  class Formatter
    def image_url(link)
      return unless retval = URI.encode(link)
      return retval unless retval["?"]
      retval.split("?").first
    end

    def time(opts)
      site, time = opts[:site], opts[:time]
      return unless time
      Time.zone = site.try(:timezone) || DEFAULT_LISTING_TIMEZONE
      begin
        Time.zone.parse(time).utc || Time.strptime(time, "%m/%d/%Y %H:%M:%S").utc
      rescue ArgumentError
        Time.strptime(time, "%m/%d/%Y %H:%M:%S").utc
      end
    end

    def price(price)
      return nil unless price

      # All prices are in cents
      stripped_price = price.strip.gsub(" ", "").sub("$","").sub(",","")
      if stripped_price[/\.\d\d\.\D*\z/]
        stripped_price.gsub(".","").to_i
      elsif stripped_price[/\.\d\.\D*\z/]
        stripped_price.gsub(".","").to_i
      elsif stripped_price[/\.\D*\z/]
        stripped_price.sub(".","").to_i * 100
      elsif stripped_price[/\.\d\D*\z/]
        stripped_price.sub(".","").to_i * 10
      elsif stripped_price[/\.\d\d\D*\z/]
        stripped_price.sub(".","").to_i
      else
        stripped_price.sub(".","").to_i * 100
      end
    end
  end

  def self.image_url(link)
    Formatter.new.image_url(link)
  end

  def self.time(opts)
    Formatter.new.time(opts)
  end

  def self.price(price)
    Formatter.new.price(price)
  end
end
