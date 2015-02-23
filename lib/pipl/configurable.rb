module Pipl

  module Configurable

    SHOW_SOURCES_ALL = 'all'
    SHOW_SOURCES_MATCHING = 'matching'
    SHOW_SOURCES_NONE = 'false'

    attr_accessor :api_key, :minimum_probability, :minimum_match, :hide_sponsored, :live_feeds, :show_sources
    attr_accessor :user_agent
    attr_writer :api_endpoint

    class << self

      def keys
        @keys ||= [
            :api_key,
            :minimum_probability,
            :minimum_match,
            :hide_sponsored,
            :live_feeds,
            :show_sources,
            :api_endpoint,
            :user_agent
        ]
      end

    end

    def configure
      yield self
    end

    def reset!
      Pipl::Configurable.keys.each do |key|
        instance_variable_set(:"@#{key}", Pipl::Default.options[key])
      end
      self
    end

    alias setup reset!

    def api_endpoint
      File.join(@api_endpoint, '')
    end

    private

    def options
      Hash[Pipl::Configurable.keys.map { |key| [key, instance_variable_get(:"@#{key}")] }]
    end

  end
end
