Stretched::Extension.define "globals/extensions/conversions" do
  extension do

    def restrict_to_range(num, opts)
      min, max = opts[:min], opts[:max]
      num && (num > min && num < max) ? num : nil
    end

    def calculate_discount_in_cents(list, sale)
      return if list.to_i.zero? || sale.to_i.zero?
      return unless list > sale
      list - sale
    end

    def calculate_discount_percent(list, sale)
      return unless discount_amount = calculate_discount_in_cents(list, sale)
      ((discount_amount.to_f / list.to_f) * 100).round
    end

    def convert_dollars_to_cents(result)
      return unless result

      # All prices are in cents
      stripped_price = result.strip.gsub(" ", "").sub("$","").sub(",","")
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

    def convert_time(opts)
      return unless time_string = opts[:time]
      timezone = opts[:timezone] || DEFAULT_LISTING_TIMEZONE

      begin
        ActiveSupport::TimeZone[timezone].parse(time_string).utc || Time.strptime(time, "%m/%d/%Y %H:%M:%S").utc
      rescue ArgumentError
        Time.strptime(time, "%m/%d/%Y %H:%M:%S").utc
      end
    end

    def clean_up_url(url)
      return unless url
      URI.parse(url)
      url
    rescue URI::InvalidURIError
      escape_url(url)
    end

    def clean_up_image_url(link)
      return unless retval = clean_up_url(link)
      retval = retval.split("?").first
      return unless is_valid_image_url?(retval)
      retval
    end

    def is_valid_image_url?(link)
      return false unless is_valid_url?(link)
      extensions = %w(.png .jpg .jpeg .gif .bmp)
      extensions.select { |ext| link.downcase[ext] }.any?
    end

    def is_valid_url?(link)
      begin
        uri = URI.parse(link)
        %w( http https ).include?(uri.scheme)
      rescue URI::BadURIError
        return false
      rescue URI::InvalidURIError
        return false
      end
    end

    def avantlink_feed_link_postfix
      (Time.now - 1.day).strftime("%Y-%m-%d")
    end

    def escape_url(url)
      Addressable::URI.escape(url)
    rescue
      nil
    end

  end
end
