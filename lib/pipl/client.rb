require 'uri'
require 'net/http'

require_relative 'configurable'
require_relative 'containers'
require_relative 'errors'
require_relative 'response'


module Pipl

  class Client

    include Pipl::Configurable

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

      if opts[:country] || opts[:state] || opts[:city]
        person.add_field Pipl::Address.new(country: opts[:country], state: opts[:state], city: opts[:city])
      end

      if opts[:phone]
        if opts[:phone].is_a? String
          person.add_field Pipl::Phone(raw: opts[:phone])
        else
          person.add_field Pipl::Phone.new(number: opts[:phone])
        end
      end

      if opts[:from_age] || opts[:to_age]
        person.add_field Pipl::DOB.from_age_range(opts[:from_age] || 0, opts[:to_age] || 1000)
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
          raise ArgumentError.new('At least one valid name/username/phone/email is required for search')
        end
      end

      if opts[:strict_validation]
        unless [nil, 'and', 'or'].include?(opts[:query_params_mode])
          raise ArgumentError.new('query_params_match should be one of "and"/"or"')
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
      keys = %w(minimum_probability possible_results hide_sponsored live_feeds show_sources)
      query_params = ["key=#{opts[:api_key]}"] + keys.map { |k| "#{k}=#{opts[k]}" unless opts[k].nil? }
      uri.query = query_params.compact.join('&')

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
        SearchResponse.from_json(response.body)
      else
        raise Pipl::APIError.from_json(response.body)
      end
    end

    def do_send_async(http, req, callback)
      Thread.new do
        begin
          response = http.request(req)
          if response.is_a? Net::HTTPSuccess
            callback.call response: SearchResponse.from_json(response.body)
          else
            callback.call error: Pipl::APIError.from_json(response.body)
          end
        rescue Exception => msg
          callback.call error: msg
        end
      end
    end

  end
end
