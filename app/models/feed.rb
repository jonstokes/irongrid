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
      next unless xml = product_xml(product)
      next unless doc = Nokogiri::XML(xml)
      url = doc.at_xpath(product_link_xpath).try(:text)
      yield(
        url:    url,
        doc:    doc
      )
    end
  end

  def each_link
    links.each do |link|
      yield "#{product_link_prefix}#{link.text}"
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
      else
        get_page(feed_url, force_format: format).try(:doc)
      end
    end
  end

  def product_xml(product)
    return unless product
    xml_prefix = '<?xml version="1.0" encoding="us-ascii"?>' + "\n"
    begin
      xml_prefix + product.to_xml
    rescue Encoding::UndefinedConversionError => e
      File.open("tmp/broken-#{Time.now.to_i}.xml", "w") do |f|
        f.puts @feed_doc
      end
      raise e
    end
  end
end

