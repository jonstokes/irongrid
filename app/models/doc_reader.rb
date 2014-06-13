class DocReader

  attr_reader :doc, :url

  def initialize(opts)
    @doc = opts[:doc]
    @url = opts[:url]
    @respond_to = []
    @coder = HTMLEntities.new
  end

  def find_by_xpath(arguments)
    nodes = doc.xpath(arguments['xpath'])
    target = get_target_text(arguments, nodes)
    target = asciify_target_text(target)
    return sanitize(target) unless arguments['filters']
    target = filter_target_text(arguments['filters'], target)
    sanitize(target)
  end

  def sanitize(text)
    return unless str = Sanitize.clean(text, elements: [])
    @coder.decode(str)
  end

  def classify_by_url(args)
    return args['type'] if "#{url}"[args['regexp']]
  end

  def classify_by_xpath(args)
    return args['type'] if find_by_xpath(args)
  end

  def classify_by_meta_keywords(args)
    return args['type'] if meta_keywords && meta_keywords[args['regexp']]
  end

  def classify_by_meta_tag(args)
    args['type'] if find_by_meta_tag(args)
  end

  def meta_property(args)
    args.merge!('attribute' => 'property')
    find_by_meta_tag(args)
  end

  def meta_name(args)
    args.merge!('attribute' => 'name')
    find_by_meta_tag(args)
  end

  def find_by_meta_tag(args)
    nodes = get_nodes_for_meta_attribute(args)
    return unless content = get_content_for_meta_nodes(nodes)
    content = content[args['regexp']] if args['regexp']
    return content unless args['filters']
    filter_target_text(args['filters'], content)
  end

  def get_nodes_for_meta_attribute(args)
    attribute = args['attribute']
    value_variations = [:upcase, :downcase, :capitalize].map { |method| args['value'].send(method) }
    nodes = value_variations.map do |value|
      doc.at_xpath(".//head/meta[@#{attribute}=\"#{value}\"]")
    end.compact
    return if nodes.empty?
    nodes
  end

  def get_content_for_meta_nodes(nodes)
    return unless nodes && nodes.any?
    contents = nodes.map { |node| node.attribute("content") }.compact
    return if contents.empty?
    content = contents.first.value.strip.squeeze(" ")
    return unless content.present?
    content
  end

  def get_target_text(arguments, nodes)
    return unless nodes && nodes.any?
    text_nodes = nodes.map { |node| node.text }.compact
    if regexp = arguments['regexp']
      if arguments['all_nodes']
        result = text_nodes.select { |node| node[regexp] }.reduce(&:+)
        return result[regexp] if result
      else
        result = text_nodes.find { |node| node[regexp] }
        return result ? result[regexp] : nil
      end
    else
      if arguments['all_nodes']
        result = text_nodes.select { |node| !node.strip.empty? }.reduce(&:+)
        return result.strip.gsub(/\s+/," ").squeeze(" ") if result
      else
        result = text_nodes.find { |node| !node.strip.empty? }
        return result ? result.strip.squeeze(" ") : nil
      end
    end
    nil
  rescue Java::JavaNioCharset::UnsupportedCharsetException
    return nil
  end

  def filter_target_text(filters, target)
    return unless target.present?
    filters.each do |filter|
      break if target.nil?
      if filter["accept"]
        target = target[filter["accept"]]
      elsif filter["reject"]
        target.slice!(filter["reject"])
      elsif filter["prefix"]
        target = "#{filter["prefix"]}#{target}"
      elsif filter["postfix"]
        target = "#{target}#{filter["postfix"]}"
      end
    end
    target.try(:strip)
  end

  def asciify_target_text(target)
    return unless target
    newstr = ""
    target.each_char { |chr| newstr << (chr.dump["u{e2}"] ? '"' : chr) }
    newstr.to_ascii
  end

  def method_missing(method_id, *arguments, &block)
    if method_id.to_s[/\Ameta\_/]
      define_and_call_meta_method(method_id)
    elsif method_id.to_s['schema_']
      define_and_call_schema_method(method_id)
    else
      super
    end
  end

  def define_and_call_meta_method(method_id)
    self.class.send :define_method, method_id do
      value = method_id.to_s.gsub("meta_og_", "").gsub("meta_", "")
      if method_id.to_s['_og_']
        meta_property('value' => "og:#{value}")
      else
        meta_name('value' => value)
      end
    end
    @respond_to << method_id
    self.send(method_id)
  end

  def define_and_call_schema_method(method_id)
    self.class.send :define_method, method_id do
      value = method_id.to_s.gsub("schema_", "")
      string_methods = [:upcase, :downcase, :capitalize]
      nodes = string_methods.map do |method|
        doc.at_xpath("//*[@itemprop=\"#{value.send(method)}\"]")
      end.compact
      return if nodes.empty?
      content = nodes.compact.first.text.strip.squeeze(" ")
      return unless content.present?
      content
    end
    @respond_to << method_id
    self.send(method_id)
  end

  def respond_to?(method_id, include_private = false)
    @respond_to && @respond_to.include?(method_id) ? true : super
  end
end
