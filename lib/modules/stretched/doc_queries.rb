module Stretched
  module DocQueries

    #
    # Doc query methods
    #

    def find_by_xpath(arguments)
      arguments.stringify_keys!
      nodes = doc.xpath(arguments['xpath'])
      target = get_target_text(arguments, nodes)
      target = asciify_target_text(target)
      sanitize(target)
    end

    def label_by_url(args)
      args.stringify_keys!
      return args['type'] if "#{url}"[args['pattern']]
    end

    def label_by_xpath(args)
      args.stringify_keys!
      return args['type'] if find_by_xpath(args)
    end

    def label_by_meta_tag(args)
      args.stringify_keys!
      args['type'] if find_by_meta_tag(args)
    end

    def find_by_meta_tag(args)
      args.stringify_keys!
      nodes = get_nodes_for_meta_attribute(args)
      return unless content = get_content_for_meta_nodes(nodes)
      content = content[args['pattern']] if args['pattern']
      return content unless args['filters']
      filter_target_text(args['filters'], content)
    end

    def find_by_schema_tag(value)
      string_methods = [:upcase, :downcase, :capitalize]
      nodes = string_methods.map do |method|
        doc.at_xpath("//*[@itemprop=\"#{value.send(method)}\"]")
      end.compact
      return if nodes.empty?
      content = nodes.compact.first.text.strip.squeeze(" ")
      return unless content.present?
      content
    end

    def filters(target, args)
      args.map do |filter|
        filter.stringify_keys! if filter.is_a?(Hash)
      end
      target = filter_target_text(target, args)
      sanitize(target)
    end

    #
    # Meta tag convenience methods
    #
    def meta_property(args)
      args.stringify_keys!
      args.merge!('attribute' => 'property')
      find_by_meta_tag(args)
    end

    def meta_name(args)
      args.stringify_keys!
      args.merge!('attribute' => 'name')
      find_by_meta_tag(args)
    end

    def meta_og(value)
      meta_property('value' => "og:#{value}")
    end

    def meta_title; meta_name('value' => 'title'); end
    def meta_keywords; meta_name('value' => 'keywords'); end
    def meta_description; meta_name('value' => 'description'); end
    def meta_image; meta_name('value' => 'image'); end

    def meta_og_title; meta_og('title'); end
    def meta_og_keywords; meta_og('keywords'); end
    def meta_og_description; meta_og('description'); end
    def meta_og_image; meta_og('image'); end

    def label_by_meta_keywords(args)
      return args['type'] if meta_keywords && meta_keywords[args['pattern']]
    end

    #
    # Schema.org convenience mthods
    #

    def schema_price; find_by_schema_tag("price"); end
    def schema_name; find_by_schema_tag("name"); end
    def schema_description; find_by_schema_tag("description"); end

    #
    # Private
    #

    def sanitize(text)
      return unless str = Sanitize.clean(text, elements: [])
      HTMLEntities.new.decode(str)
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
      if pattern = arguments['pattern']
        if arguments['all_nodes']
          result = text_nodes.select { |node| node[pattern] }.reduce(&:+)
          return result[pattern] if result
        else
          result = text_nodes.find { |node| node[pattern] }
          return result ? result[pattern] : nil
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

    def filter_target_text(target, args)
      return unless target.present?
      args.each do |filter|
        break if target.nil?
        if args.is_a?(String) && respond_to?(args)
          target = send(filter, target)
        elsif filter["accept"]
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
  end
end
