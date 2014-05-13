class SoftCategorize
  include Interactor
  include Retryable
  include Notifier

  HIT_THRESHOLD = 2

  def perform
    if category1.classification_type == "fall_through"
      context[:category1] = metadata_categorize ||
        soft_categorize ||
        ElasticSearchObject.new(
          "category1",
          raw:                  "None",
          classification_type: "fall_through"
        )
    end
  end

  def metadata_categorize
    return unless context[:grains] && context[:number_of_rounds] && context[:caliber]
      ElasticSearchObject.new(
        "category1",
        raw:                  "Ammunition",
        classification_type:  "metadata"
      )
  end

  def soft_categorize
    search_options.each_with_index do |opts, i|
      next unless category = categorize_with_search_index(opts)
      return ElasticSearchObject.new(
        "category1",
        raw: category,
        classification_type: "soft",
        score: i
      )
    end
    nil
  end

  def categorize_with_search_index(opts)
    return unless search = get_search(opts)

    # Pull the results by relevance, and return the most popular category from among those
    vote_tally = {}
    search.results.each do |result|
      #> result.category1
      #=> [{'category1' => 'Guns'}, {'classification_type' => 'hard'}]
      if category = result.category1.detect { |v| v["category1"] }.try(:[], "category1")
        vote_tally[category] ||= 0
        vote_tally[category] += 1
      end
    end
    return vote_tally.sort_by { |k,v| v.to_i }.last.first if vote_tally.any?
    nil
  end

  def get_search(opts)
    return unless s = retryable_search do
      Tire::Search::Search.new(Listing.index_name, load:false) do |search|
        search.query do |query|
          query_opts = { :default_operator => "AND", :phrase_slop => opts[:slop] }
          query.string ElasticTools::QueryPreParser.escape_query(title.raw), query_opts
        end
        filters(opts).each { |k, v| search.filter k, v }
        search.size 100
      end
    end
    return s if retryable { s.results.count } >= HIT_THRESHOLD
    return nil
  end

  def filters(opts)
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
      filters.merge!( term: { "category1.classification_type" => category_type })
    else
      filters.merge!( not: { term: { "category1.classification_type" => "fall_through" } } )
    end

    filters
  end

  def search_options
    @search_options ||= [
      {:slop => 0, :category_type => "hard",     :price_range => price_range },
      {:slop => 1, :category_type => "hard",     :price_range => price_range },
      {:slop => 0, :category_type => "metadata", :price_range => price_range },
      {:slop => 1, :category_type => "metadata", :price_range => price_range },
      {:slop => 1, :category_type => "hard" },
      {:slop => 1, :category_type => "metadata" },
    ]
  end

  def price_range
    @price_range ||= begin
      price_range_bottom = (current_price_in_cents - (current_price_in_cents * 0.20)).to_i
      price_range_bottom = 0 if current_price_in_cents < 0
      price_range_top = (current_price_in_cents + (current_price_in_cents * 0.20)).to_i
      price_range_top = 100000000  if price_range_top <= price_range_bottom
      (price_range_bottom..price_range_top)
    end
  end

  def retryable_search(&block)
    retries, interval = 5, 1
    begin
      return yield
    rescue Exception => e
      if e.message[/REQUEST FAILED/]
        notify "Bad search request when matching a category for #{@url} with title #{title.raw}"
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
