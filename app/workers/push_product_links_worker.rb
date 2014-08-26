class PushProductLinksWorker < CoreWorker

  def init(opts)

  end

  def perform
    return false unless init(opts)
    while !finished? && link = @object_q.pop

      session_q.push(
        queue: queue,
        session_definition: session_definition(link),
        object_adapters: object_adapters(link),
        urls: urls(link)
      )
    end
  end

  def product_session_format
    return {} unless page_adapter
    {
      'queue' => domain,
      'session_definition' => session_def(adapter_format),
      'object_adapters' => [ "#{domain}/product_page" ]
    }
  end

  def sessions
    @sessions ||= begin
      session_list = []
      url_list = []
      urls.each do |url|
        if url_count(url_list) >= 300
          session_list << session_hash(url_list)
          url_list = []
        else
          url_list << url
        end
      end
      session_list << session_hash(url_list)
      session_list
    end
  end

  def url_count(url_list)
    count = 0
    url_list.each do |url|
      if url['start_at_page']
        count += url['stop_at_page']
      else
        count += 1
      end
    end
    count
  end

  def session_hash(url_list)
    {
      'queue' => domain,
      'session_definition' => session_def(feed_format),
      'object_adapters' => adapters_for_sessions,
      'urls' => url_list
    }
  end
end
