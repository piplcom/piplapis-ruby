require 'uri'
require 'net/http'

require_relative 'configurable'
require_relative 'containers'
require_relative 'errors'
require_relative 'fields'
require_relative 'response'


module Pipl

  class Client

    include Pipl::Configurable

    QUERY_PARAMS = %w(minimum_probability minimum_match hide_sponsored live_feeds show_sources match_requirements
                source_category_requirements infer_persons)

    def initialize(options = {})
      Pipl::Configurable.keys.each do |key|
        instance_variable_set(:"@#{key}", options[key] || Pipl.instance_variable_get(:"@#{key}"))
      end

    end

    def same_options?(opts)
      opts.hash == options.hash
    end

    def search(params={})
      opts = options.merge params
      create_search_person(opts)
      validate_search_params(opts)
      http, req = create_http_request(opts)
      if opts.key? :callback
        do_send_async http, req, opts[:callback]
      elsif opts[:async] and block_given?
        do_send_async http, req, Proc.new
      else
        do_send http, req
      end
    end

    private

    def create_search_person(opts)
      return if opts.key? :search_pointer

      person = opts[:person] || Pipl::Person.new
      person.add_field Pipl::Name.new(raw: opts[:raw_name]) if opts[:raw_name]
      person.add_field Pipl::Email.new(address: opts[:email]) if opts[:email]
      person.add_field Pipl::Username.new(content: opts[:username]) if opts[:username]
      person.add_field Pipl::Address.new(raw: opts[:raw_address]) if opts[:raw_address]

      if opts[:first_name] || opts[:middle_name] || opts[:last_name]
        person.add_field Pipl::Name.new(first: opts[:first_name], middle: opts[:middle_name], last: opts[:last_name])
      end

      if opts[:country] || opts[:state] || opts[:city] || opts[:zip_code]
        person.add_field Pipl::Address.new(country: opts[:country], state: opts[:state], city: opts[:city], zip_code: opts[:zip_code])
      end

      if opts[:phone]
        if opts[:phone].is_a? String
          person.add_field Pipl::Phone.new(raw: opts[:phone])
        else
          person.add_field Pipl::Phone.new(number: opts[:phone])
        end
      end

      if opts[:from_age] || opts[:to_age]
        person.add_field Pipl::DOB.from_age_range((opts[:from_age] || 0).to_i, (opts[:to_age].to_i || 1000).to_i)
      end

      opts[:person] = person
    end

    def validate_search_params(opts)
      unless opts[:api_key] and not opts[:api_key].empty?
        raise ArgumentError.new('API key is missing')
      end

      if opts[:search_pointer] and opts[:search_pointer].empty?
        raise ArgumentError.new('Given search pointer is empty')
      end

      unless opts.key? :search_pointer
        unless opts[:person] and opts[:person].is_searchable?
          raise ArgumentError.new('No valid name/username/user_id/phone/email/address or search pointer in request')
        end
      end

      if opts[:strict_validation]
        if opts[:minimum_probability] and not (0..1).include? opts[:minimum_probability]
          raise ArgumentError.new('minimum_probability must be a float in 0..1')
        end

        if opts[:minimum_match] and not (0..1).include? opts[:minimum_match]
          raise ArgumentError.new('minimum_match must be a float in 0..1')
        end

        unless [Pipl::Configurable::SHOW_SOURCES_ALL,
                Pipl::Configurable::SHOW_SOURCES_MATCHING,
                Pipl::Configurable::SHOW_SOURCES_NONE, nil, true, false].include? opts[:show_sources]
          raise ArgumentError.new('show_sources must be one of all, matching, false or a boolean value')
        end

        if opts[:match_requirements] and not opts[:match_requirements].is_a? String
          raise ArgumentError.new('match_requirements must be a String')
        end

        if opts[:source_category_requirements] and not opts[:source_category_requirements].is_a? String
          raise ArgumentError.new('source_category_requirements must be a String')
        end

        if opts[:infer_persons] and not [nil, false, true].include? opts[:infer_persons]
          raise ArgumentError.new('infer_persons must be true, false or nil')
        end

        unless opts.key? :search_pointer
          unsearchable = opts[:person].unsearchable_fields
          if unsearchable and not unsearchable.empty?
            raise ArgumentError.new("Some fields are unsearchable: #{unsearchable}")
          end
        end
      end
    end

    def create_http_request(opts)
      uri = URI(opts[:api_endpoint])
      query_params = ["key=#{opts[:api_key]}"] +
          QUERY_PARAMS.map { |k| "#{k}=#{opts[k.to_sym]}" unless opts[k.to_sym].nil? }
      query_params << opts[:extra] or []
      query_params << uri.query
      uri.query = URI.escape(query_params.compact.join('&'))

      req = Net::HTTP::Post.new(uri.request_uri)
      req['User-Agent'] = opts[:user_agent]
      if opts.key? :search_pointer
        req.set_form_data search_pointer: opts[:search_pointer]
      else
        h = opts[:person].to_hash
        req.set_form_data person: h.reject { |_, value| value.nil? }.to_json
      end

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == 'https'
      http.open_timeout = opts[:http_timeout]

      [http, req]
    end

    def do_send(http, req)
      response = http.request(req)
      if response.is_a? Net::HTTPSuccess
        SearchResponse.from_http_response(response)
      else
        raise Pipl::Client::APIError.from_http_response(response)
      end
    end

    def do_send_async(http, req, callback)
      Thread.new do
        begin
          response = do_send http, req
          callback.call response: response
        rescue Pipl::Client::APIError => err
          callback.call error: err
        rescue Exception => msg
          callback.call error: msg
        end
      end
    end

  end
end
