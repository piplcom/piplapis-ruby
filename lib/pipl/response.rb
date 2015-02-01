require 'json'

require_relative 'containers'

module Pipl

  class Client

    class SearchResponse

      attr_reader :query, :person, :sources, :possible_persons, :warnings

      def initialize(params={})
        @query = params[:query]
        @person = params[:person]
        @sources = params[:sources]
        @possible_persons = params[:possible_persons]
        @warnings = params[:warnings]
      end

      def self.from_json(json_str)
        h = JSON.parse(json_str, symbolize_names: true)

        params = {}
        params[:query] = Pipl::Person.from_hash(h[:query]) if h.key? :query
        params[:person] = Pipl::Person.from_hash(h[:person]) if h.key? :person
        params[:sources] = h[:sources].map { |s| Pipl::Source.from_hash(s) } if h.key? :sources
        params[:possible_persons] = h[:possible_persons].map { |p| Pipl::Person.from_hash(p) } if h.key? :possible_persons
        params[:warnings] = h[:warnings]

        self.new(params)
      end

      def matching_sources
        @sources.select { |s| s.match == 1.0 } if @sources
      end

      def group_sources_by_domain
        @sources.group_by { |s| s.domain } if @sources
      end

      def group_sources_by_category
        @sources.group_by { |s| s.category } if @sources
      end

      def group_sources_by_match
        @sources.group_by { |s| s.match } if @sources
      end

      def gender
        @person.gender if @person
      end

      def age
        @person.age if @person
      end

      def job
        @person.job if @person
      end

      def address
        @person.address if @person
      end

      def education
        @person.education if @person
      end

      def language
        @person.language if @person
      end

      def ethnicity
        @person.ethnicity if @person
      end

      def origin_country
        @person.origin_country if @person
      end

      def phone
        @person.phone if @person
      end

      def email
        @person.email if @person
      end

    end
  end

end
