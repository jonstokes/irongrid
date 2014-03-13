if Rails.env.production?
  Tire.configure do
    url Figaro.env.elasticsearch_index_remote
  end
else
  Tire.configure do
    logger "log/#{Rails.env}.log", :level => 'debug'
  end
end


module Tire
  Index.class_eval do
    def register_percolator_query_as_json(name, json)
      # See Tire::Search::Search.to_curl for ref on escaping the json
      json.gsub!("'", '\u0027')

      @response = Configuration.client.put "#{Configuration.url}/#{@name}/.percolator/#{name}", json
      MultiJson.decode(@response.body)['ok']

    ensure
      curl = %Q|curl -X PUT "#{Configuration.url}/#{@name}/.percolator/#{name}?pretty" -d '#{json}'|
      logged('.percolator', curl)
    end

    def unregister_percolator_query(name)
      @response = Configuration.client.delete "#{Configuration.url}/#{@name}/.percolator/#{name}"
      MultiJson.decode(@response.body)['ok']

    ensure
      curl = %Q|curl -X DELETE "#{Configuration.url}/#{@name}/.percolator/#{name}"|
      logged('.percolator', curl)
    end

    def analyze_with_local(text, options={})
      options = {:pretty => true}.update(options)
      params  = options.to_param
      @response = Configuration.client.get "#{Figaro.env.elasticsearch_index_local}/#{Listing.index_name}/_analyze?#{params}", text
      @response.success? ? MultiJson.decode(@response.body) : false

    ensure
      curl = %Q|curl -X GET "#{Figaro.env.elasticsearch_index_local}/#{Listing.index_name}/_analyze?#{params}" -d '#{text}'|
      logged('_analyze', curl)
    end
  end
end
