module ListingCategorizer
  extend ActiveSupport::Concern

  #FIXME: This should be an interactor

  def hard_categorize(cat)
    result = raw_listing[cat]
    result ? {cat => result, "classification_type" => "hard"} : nil
  end

  def default_categorize(cat)
    result = site.send("default_#{cat}")
    result ? {cat => result, "classification_type" => "default"} : nil
  end

  def soft_categorize(cat)
    return nil unless scrubbed[:title]
    soft_category_options.each_with_index do |opts, i|
      next unless opts
      result = categorize_with_search_index(cat, opts)
      return {cat => result, "classification_type" => "soft", "score" => i} if result
    end
    return nil
  end

  def soft_category_options
    if current_price_in_cents.try(:>, 0)
      range = get_price_range
      opts_array = [
        {:slop => 0, :category_type => "hard", :price_range => range },
        {:slop => 1, :category_type => "hard", :price_range => range },
        {:slop => 1, :category_type => "hard"}
      ]
    else
      opts_array =[nil, nil, nil] # Pad the array out so that the score is correct
    end

    opts_array += [
      {:slop => 1, :price_threshold => (range.try(:first) || 100)},
      {:slop => 1},
    ]
  end

  def categorize_with_search_index(cat, opts)
    return nil unless search = get_search(cat, opts)
    return nil unless retryable { search.results.count } >= 2

    # Pull the results by relevance, and return the most popular category from among those
    category_hash = {}
    search.results.each do |result|
      if category = result.send(cat)
        category_hash[category] ||= 0
        category_hash[category] += 1
      end
    end
    category_hash.any? ? category_hash.sort_by { |k,v| v.to_i }.last.first : nil
  end

  def get_search(cat, opts)
    slop = opts[:slop]
    return nil unless s = retryable_search do
      Tire::Search::Search.new(Listing.index_name, load:false) do |search|
        search.query do |query|
          query.string ElasticTools::QueryPreParser.escape_query(scrubbed[:title]),  { :default_operator => "AND", :phrase_slop => slop }
        end
        category_filters(cat, opts).each { |k, v| search.filter k, v }
        search.size 100
      end
    end
    return s
  end

  def category_filters(cat, opts)
    price_threshold, price_range, category_type = opts[:price_threshold], opts[:price_range], opts[:category_type]
    filters = {}

    if price_range
      lower_bound = price_threshold || price_range.min
      upper_bound = price_range.max
      filters.merge!( range: { current_price_in_cents: { from: lower_bound, to: upper_bound } } )
    elsif price_threshold
      filters.merge!( range: { current_price_in_cents: { gte: price_threshold } } )
    end

    if category_type
      filters.merge!( term: { "#{cat}.classification_type" => category_type })
    else
      filters.merge!( not: { term: { "#{cat}.classification_type" => "fall_through" } } )
    end

    filters
  end

  def get_price_range(percent=0.25)
    price = current_price_in_cents
    pc = 0.01 * percent
    price_range_bottom = (price - (price * 0.20)).to_i
    price_range_bottom = 0 if price < 0
    price_range_top = (price + (price * 0.20)).to_i
    (price_range_bottom..price_range_top)
  end

  def retryable_search(&block)
    retries, interval = 5, 1
    begin
      return yield
    rescue Exception => e
      if e.message[/REQUEST FAILED/]
        notify "Bad search request when matching a category for #{@url} with title #{title}"
      else
        sleep interval
        retry if (retries -= 1).zero?
      end
    rescue Exception
      sleep interval
      retry if (retries -= 1).zero?
    end
    return nil
  end
end
