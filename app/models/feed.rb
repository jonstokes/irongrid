class Feed
  include PageUtils
  include Notifier
  attr_reader :options

  %w(
    url
    filename
    postfix
    refresh_interval
    product_xpath
    product_link_xpath
    product_link_prefix
  ).each do |key|
    define_method key do
      @options[key.to_sym]
    end
  end

  def initialize(opts)
    #NOTE: The :filename option is for the affiliate_setup rake task, which is used when
    # a seller's complete inventory is first loaded into the db from
    # a very large local xml file. Later updates come via the feed url.
    @options = opts.symbolize_keys
  end

  def format
    @options[:format].try(:to_sym) || :html
  end

  def each_product
    products.each do |product|
      url = product.at_xpath(product_link_xpath).try(:text)
      yield(
        url: url,
        doc: product
      )
    end
  end

  def each_link
    links.each do |link|
      yield "#{product_link_prefix}#{link.text.strip}"
    end
  end

  def products
    return [] unless feed_doc && product_xpath
    feed_doc.xpath(product_xpath)
  end

  def links
    return [] unless feed_doc && product_link_xpath
    feed_doc.xpath(product_link_xpath)
  end

  def feed_url
    return nil if filename
    @feed_url ||= postfix ? (url + eval(postfix)) : url
  end

  def feed_doc
    @feed_doc ||= begin
      notify "  Downloading #{feed_url || filename}..."
      if filename
        Nokogiri::XML(File.open(filename).read) rescue nil
      elsif format == :dhtml
        render_page(feed_url).try(:doc)
      else
        get_page(feed_url, force_format: format).try(:doc)
      end
    end
  end

  def clear!
    @feed_doc = nil
    @http.close if @http
  end
end

