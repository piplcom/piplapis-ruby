require_relative 'version'

module Pipl

  module Default

    API_ENDPOINT = 'https://api.pipl.com/search/'.freeze
    API_KEY = 'sample_key'.freeze
    USER_AGENT   = "piplapis/ruby/#{Pipl::VERSION}".freeze

    class << self

      def options
        Hash[Pipl::Configurable.keys.map{|key| [key, send(key)]}]
      end

      def api_key
        ENV.fetch 'PIPL_API_KEY', API_KEY
      end

      def minimum_probability
        ENV['PIPL_MINIMUM_PROBABILITY']
      end

      def minimum_match
        ENV['PIPL_MINIMUM_MATCH']
      end

      def hide_sponsored
        ENV['PIPL_HIDE_SPONSORED']
      end

      def live_feeds
        ENV['PIPL_LIVE_FEEDS']
      end

      def show_sources
        ENV['PIPL_SHOW_SOURCES']
      end

      def strict_validation
        ENV['PIPL_USER_STRICT_VALIDATION']
      end

      def api_endpoint
        ENV.fetch 'PIPL_API_ENDPOINT', API_ENDPOINT
      end

      def user_agent
        ENV.fetch 'PIPL_USER_AGENT', USER_AGENT
      end

    end
  end
end
