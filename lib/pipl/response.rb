require 'json'

require_relative 'containers'

module Pipl

  class Client

    class SearchResponse

      attr_reader :query, :person, :sources, :possible_persons, :warnings, :visible_sources, :available_sources
      attr_reader :search_id, :http_status_code, :raw_response, :available_data, :match_requirements
      attr_reader :source_category_requirements, :person_count
      attr_reader :qps_allotted, :qps_current, :qps_live_allotted, :qps_live_current, :qps_demo_allotted,
                  :qps_demo_current, :quota_allotted, :quota_current, :quota_reset, :demo_usage_allotted,
                  :demo_usage_current, :demo_usage_expiry


      def initialize(params={})
        @query = params[:query]
        @person = params[:person]
        @sources = params[:sources]
        @possible_persons = params[:possible_persons]
        @warnings = params[:warnings]
        @visible_sources = params[:visible_sources]
        @available_sources = params[:available_sources]
        @search_id = params[:search_id]
        @http_status_code = params[:http_status_code]
        @raw_response = params[:raw_response]
        @available_data = params[:available_data]
        @match_requirements = params[:match_requirements]
        @source_category_requirements = params[:source_category_requirements]
        @person_count = params[:person_count]
        @qps_allotted = params[:qps_allotted]
        @qps_current = params[:qps_current]
        @qps_live_allotted = params[:qps_live_allotted]
        @qps_live_current = params[:qps_live_current]
        @qps_demo_allotted = params[:qps_demo_allotted]
        @qps_demo_current = params[:qps_demo_current]
        @quota_allotted = params[:quota_allotted]
        @quota_current = params[:quota_current]
        @quota_reset = params[:quota_reset]
        @demo_usage_allotted = params[:demo_usage_allotted]
        @demo_usage_current = params[:demo_usage_current]
        @demo_usage_expiry = params[:demo_usage_expiry]
      end

      def self.deserialize(json_str, headers={})
        h = JSON.parse(json_str, symbolize_names: true)

        params = {}
        params[:query] = Pipl::Person.from_hash(h[:query]) if h.key? :query
        params[:person] = Pipl::Person.from_hash(h[:person]) if h.key? :person
        params[:sources] = h[:sources].map { |s| Pipl::Source.from_hash(s) } if h.key? :sources
        params[:possible_persons] = h[:possible_persons].map { |p| Pipl::Person.from_hash(p) } if h.key? :possible_persons
        params[:warnings] = h[:warnings]
        params[:visible_sources] = h[:@visible_sources]
        params[:available_sources] = h[:@available_sources]
        params[:search_id] = h[:@search_id]
        params[:http_status_code] = h[:@http_status_code]
        params[:raw_response] = json_str
        params[:match_requirements] = h[:match_requirements]
        params[:source_category_requirements] = h[:source_category_requirements]
        params[:available_data] = AvailableData.from_hash(h[:available_data]) if h.key? :available_data

        # person_count: API v4 doesn't send this in the response so we compute it here
        if h.key? :@person_count
          params[:person_count] = h[:@person_count]
        elsif h.key?(:person)
          params[:person_count] = 1
        elsif h.key?(:possible_persons)
          params[:person_count] = h[:possible_persons].length
        else
          params[:person_count] = 0
        end

        params.merge! Utils::extract_rate_limits(headers)

        self.new(params)
      end

      def self.from_http_response(resp)
        self.deserialize(resp.body, resp)
      end

      # Here for backward compatibility
      def self.from_json(json_str)
        self.deserialize(json_str)
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

      def name
        @person.name if @person
      end

      def image
        @person.image if @person
      end

      def url
        @person.url if @person
      end

      def username
        @person.username if @person
      end

      def user_id
        @person.user_id if @person
      end

      def relationship
        @person.relationship if @person
      end

      def vehicle
        @person.vehicle if @person
      end

    end

    class AvailableData
      attr_reader :basic, :premium

      def initialize(params={})
        @basic = params[:basic]
        @premium = params[:premium]
      end

      def self.from_hash(h)
        params = {}
        params[:basic] = FieldCount.new(h[:basic]) if h.key? :basic
        params[:premium] = FieldCount.new(h[:premium]) if h.key? :premium
        self.new(params)
      end

    end

    class FieldCount
      attr_reader :addresses, :ethnicities, :emails, :work_emails, :personal_emails, :dobs, :genders, :user_ids, :social_profiles, :educations, :jobs,
                  :images, :languages, :origin_countries, :names, :phones, :mobile_phones, :landline_phones, :voip_phones,
                  :relationships, :usernames, :vehicles

      def initialize(params={})
        @addresses = params[:addresses] || 0
        @ethnicities = params[:ethnicities] || 0
        @emails = params[:emails] || 0
        @work_emails = params[:work_emails] || 0
        @personal_emails = params[:personal_emails] || 0
        @dobs = params[:dobs] || 0
        @genders = params[:genders] || 0
        @user_ids = params[:user_ids] || 0
        @social_profiles = params[:social_profiles] || 0
        @educations = params[:educations] || 0
        @jobs = params[:jobs] || 0
        @images = params[:images] || 0
        @languages = params[:languages] || 0
        @origin_countries = params[:origin_countries] || 0
        @names = params[:names] || 0
        @phones = params[:phones] || 0
        @mobile_phones = params[:mobile_phones] || 0
        @voip_phones = params[:voip_phones] || 0
        @landline_phones = params[:landline_phones] || 0
        @relationships = params[:relationships] || 0
        @usernames = params[:usernames] || 0
        @vehicles = params[:vehicles] || 0
      end

    end

  end

end
