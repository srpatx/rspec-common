%i[create update delete].each do |action|
  RSpec::Matchers.define :"#{action}_elasticsearch_index_with" do |**params|
    supports_block_expectations

    match do |block|
      Doubles::Elasticsearch::Client.reset!

      block.call

      @matches = Doubles::Elasticsearch::Client.calls[action]&.select { |match| match == params }
      @matches&.one?
    end

    failure_message do
      message = "expected to #{action} Elasticsearch index with #{params.inspect}\n\n"
      message += "Actual #{action} changes to Elasticsearch indices:\n"
      Doubles::Elasticsearch::Client.calls[action]&.each do |match|
        message += "\t- #{match.inspect}"
      end
      message
    end
  end
end

RSpec::Matchers.define :bulk_update_elasticsearch_index_with do |records, index:, id_attr: :id|
  supports_block_expectations

  match do |block|
    Doubles::Elasticsearch::Client.reset!

    block.call

    @matches = Doubles::Elasticsearch::Client.calls[:bulk]

    bulk_update_params = {
      # Elasticsearch prefixes index names with "test_" in the test environment only.
      index: "test_#{index}",
      body: records.collect do |record|
        {index: {_id: record.public_send(id_attr), data: record.to_elasticsearch}}
      end
    }

    @matches&.one? && @matches.first == bulk_update_params
  end

  failure_message do
    "expected to bulk update Elasticsearch index with records #{records.collect(&:id)}"
  end
end

# rubocop:disable Metrics/BlockLength
RSpec::Matchers.define :search_elasticsearch_index do |index|
  chain :with_query do |query|
    @query = query
  end

  chain :with_aggregation do |name, attributes|
    @aggregations ||= {}
    @aggregations[name] = attributes
  end

  chain :with_body do |body|
    @body = body
  end

  match do |_results|
    @search_calls = Doubles::Elasticsearch::Client.calls[:search]
    matching = @search_calls.select { |call| call[:index] == index.to_s }

    if @query == :none
      matching = matching.select { |call| call[:body][:query][:bool][:must].empty? }
    elsif @query
      matching = matching.select { |call| call[:body][:query][:bool][:must].include?(@query) }
    end

    if @aggregations
      matching = matching.select { |call| call[:body].has_key?(:aggregations) }
      @aggregations.each do |name, attributes|
        matching = matching.select { |call| call[:body][:aggregations][name] == attributes }
      end
    end

    matching = matching.select { |call| call[:body] == @body } if @body

    matching.one?
  end

  failure_message do
    message = "expected one call to search index '#{index}'"
    message += " with query #{@query}" if @query
    @aggregations&.each do |name, attributes|
      message += " with aggregation #{name}: #{attributes}"
    end
    message += " with body\n#{@body}" if @body
    message += "\n\nActual calls:"
    @search_calls.each_with_index do |call, idx|
      message += "\n\n## Body #{idx}:\n#{call[:body]}\n## Other top-level keys:\n#{call.except(:body)}"
    end
    message
  end
end
# rubocop:enable Metrics/BlockLength
