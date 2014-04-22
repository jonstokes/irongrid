class DocReader

  attr_reader :doc, :url

  def initialize(opts)
    @doc = opts[:doc]
    @url = opts[:url]
    @respond_to = []
  end

  def at_xpath(args)
    doc.at_xpath(args)
  end

  def find_by_xpath(arguments)
    nodes = doc.xpath(arguments['xpath'])
    return nil if nodes.empty?
    return nil unless target = get_target_text(arguments, nodes)
    target = asciify_target_text(target)
    return target unless arguments['filters']
    filter_target_text(arguments['filters'], target)
  end

  def classify_url_by_regexp(args)
    return args['type'] if "#{url}"[args['regexp']]
  end

  def classify_by_xpath(args)
    return args['type'] if find_by_xpath(args)
  end

  def classify_by_meta_keywords(args)
    return args['type'] if meta_keywords && meta_keywords[args['regexp']]
  end

  def classify_by_meta_tag(args)
    string_methods = [:upcase, :downcase, :capitalize]
    attribute = args["name"]
    results = string_methods.map do |method|
      doc.at_xpath(".//head/meta[@name=\"#{attribute.send(method)}\"]")
    end.compact
    return nil if results.empty?
    attributes = results.map { |result| result.attribute("content") }.compact
    return nil if attributes.empty?
    attribute = attributes.first.value.strip.squeeze(" ")
    return nil if attribute.try(:empty?)
    if args['regexp']
      return attribute[args['regexp']] ? args['type'] : nil
    else
      return args['type']
    end
  end

  def get_target_text(arguments, nodes)
    if regexp = arguments['regexp']
      if arguments['all_nodes']
        result = nodes.select { |node| node.text && node.text[regexp] }.map(&:text).reduce(&:+)
        return result[regexp] if result
      else
        result = nodes.find { |node| node.text && node.text[regexp] }
        return result && result.text ? result.text[regexp] : nil
      end
    else
      if arguments['all_nodes']
        result = nodes.select { |node| node.text && !node.text.strip.empty? }.map(&:text).reduce(&:+)
        return result.strip.gsub(/\s+/," ").squeeze(" ") if result
      else
        result = nodes.find { |node| node.text && !node.text.strip.empty? }
        return result && result.text ? result.text.strip.squeeze(" ") : nil
      end
    end
    nil
  rescue Java::JavaNioCharset::UnsupportedCharsetException
    return nil
  end

  def filter_target_text(filters, target)
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

  #
  # Metaprogramming
  #
  def method_missing(method_id, *arguments, &block)
    if method_id.to_s['meta_']
      self.class.send :define_method, method_id do
        attribute = method_id.to_s.gsub("meta_og_", "")
        attribute = attribute.gsub("meta_", "")
        string_methods = [:upcase, :downcase, :capitalize]
        results = string_methods.map do |method|
          if method_id.to_s['_og_']
            doc.at_xpath(".//head/meta[@property=\"og:#{attribute.send(method)}\"]")
          else
            doc.at_xpath(".//head/meta[@name=\"#{attribute.send(method)}\"]")
          end
        end
        if results.compact.empty?
          return nil
        else
          attributes = results.compact.map { |result| result.attribute("content") }
          if attributes.compact.empty?
            return nil
          else
            return_value = attributes.compact.first.value.strip.squeeze(" ")
            return return_value.empty? ? nil : return_value
          end
        end
      end
      @respond_to << method_id
      self.send(method_id)
    elsif method_id.to_s['schema_']
      self.class.send :define_method, method_id do
        attribute = method_id.to_s.gsub("schema_", "")
        string_methods = [:upcase, :downcase, :capitalize]
        results = string_methods.map do |method|
          doc.at_xpath("//*[@itemprop=\"#{attribute.send(method)}\"]")
        end
        unless results.compact.empty?
          result = results.compact.first.text.strip.squeeze(" ")
          return result.empty? ? nil : result
        else
          return nil
        end
      end
      @respond_to << method_id
      self.send(method_id)
    else
      super
    end
  end

  def respond_to?(method_id, include_private = false)
    @respond_to && @respond_to.include?(method_id) ? true : super
  end
end
