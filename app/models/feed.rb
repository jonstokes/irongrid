class Feed
  include PageUtils
  include Notifier
  attr_reader :options

  %w(
    url
    postfix
    refresh_interval
    product_list_xpath
    product_link_xpath
    product_status_xpath
  ).each do |key|
    define_method key do
      @options[key]
    end
  end

  def initialize(opts)
    #NOTE: The :filename option is for the affiliate_setup rake task, which is used when
    # a seller's complete inventory is first loaded into the db from
    # a very large local xml file. Later updates come via the feed url.
    @options = opts
    @filename = opts[:filename]
    @feed_url = opts[:feed_url]
  end

  def each_product
    return [] unless parsed_xml
    parsed_xml.xpath(product_list_xpath).each do |product|
      next unless xml = product_xml(product)
      next unless doc = Nokogiri::XML(xml)
      status = doc.at_xpath(product_status_xpath).try(:text)
      url = doc.at_xpath(product_link_xpath).try(:text)
      yield(
        url:    url,
        status: status,
        doc:    doc
      )
    end
  end

  def product_count
    return 0 unless parsed_xml
    parsed_xml.xpath(product_list_xpath).count
  end

  def empty?
    return true unless parsed_xml
    parsed_xml.xpath(product_list_xpath).empty?
  end

  def feed_url
    return nil if @filename
    @feed_url ||= postfix ? (url + eval(postfix)) : url
  end

  def xml_data
    @xml_data ||= begin
      notify "  Downloading #{feed_url || @filename}..."
      if @filename
        File.open(@filename).read
      else
        get_page(feed_url).body.encode('ASCII', {:invalid => :replace, :undef => :replace, :replace => '?'}) rescue nil
      end
    end
  end

  def parsed_xml
    return unless xml_data
    @parsed_xml ||= Nokogiri::XML(xml_data)
  end

  def product_xml(product)
    return unless product
    xml_prefix = '<?xml version="1.0" encoding="us-ascii"?>' + "\n"
    begin
      xml_prefix + product.to_xml
    rescue Encoding::UndefinedConversionError => e
      File.open("tmp/broken-#{Time.now.to_i}.xml", "w") do |f|
        f.puts @xml_data
      end
      raise e
    end
  end
end

