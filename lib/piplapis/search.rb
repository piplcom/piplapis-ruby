# coding: UTF-8

module PiplApi

# Ruby wrapper for easily making calls to Pipl's Search API.
# 
# Pipl's Search API allows you to query with the information you have about
# a person (his name, address, email, phone, username and more) and in response 
# get all the data available on him on the web.
# 
# The classes contained in this module are:
# - SearchAPIRequest -- Build your request and send it.
# - SearchAPIResponse -- Holds the response from the API in case it contains data.
# - SearchAPIError -- An exception raised when the API response is an error.
# 
# The classes are based on the person data-model that's implemented here in data.rb

require 'uri'
require 'net/http'

require_relative 'error'
require_relative 'data/containers'

module SearchApi
    # Default API key value, you can set your key globally in this variable instead 
    # of passing it in each API call
    @@default_api_key = nil
    
    def self.default_api_key
        @@default_api_key
    end
    
    def self.default_api_key=key
        @@default_api_key = key
    end
end

class SearchAPIRequest
    # A request to Pipl's Search API.
    # 
    # Building the request from the query parameters can be done in two ways:
    # 
    # Option 1 - directly and quickly (for simple requests with only few 
    #            parameters):
    #         
    # require 'search'
    # request = PiplApi::SearchAPIRequest.new({ :api_key => 'samplekey', 
    #                                                            :email => 'eric@cartman.com' })
    # response = request.send()
    # 
    # Option 2 - using the data-model (useful for more complex queries; for 
    #            example, when there are multiple parameters of the same type 
    #            such as few phones or a few addresses or when you'd like to use 
    #            information beyond the usual identifiers such as name or email, 
    #            information like education, job, relationships etc):
    #         
    # require 'search'
    # require 'data/fields'
    # fields = [PiplApi::Name.new({ :first => 'Eric', :last => 'Cartman'} ),
    #             PiplApi::Address.new({ :country => 'US', :state => 'CO', :city => 'South Park' }),
    #             PiplApi::Address.new({ :country => 'US', :state => 'NY' }),
    #             PiplApi::Job.new({ :title => 'Actor' })]
    # request = PiplApi::SearchAPIRequest.new({ :api_key => 'samplekey',
    #                                                            :person => PiplApi::Person.new({ :fields => fields }) })
    # response = request.send()
    # 
    # The request also supports prioritizing/filtering the type of records you
    # prefer to get in the response (see the append_priority_rule and 
    # add_records_filter methods).
    # 
    # Sending the request and getting the response is very simple and can be done
    # by either making a blocking call to request.send() or by making 
    # a non-blocking call to request.send_async(callback) which sends the request 
    # asynchronously.
    
    attr_reader :person, :query_params_mode, :exact_name
    
    HEADERS = {'User-Agent' => 'piplapis/ruby/%s' % PiplApi::PIPLAPI_VERSION}
    BASE_URL = 'http://api.pipl.com/search/v3/json/?'
    
    def initialize(params={})
        # Initiate a new request object with given query params.
        # 
        # Each request must have at least one searchable parameter, meaning 
        # a name (at least first and last name), email, phone or username. 
        # Multiple query params are possible (for example querying by both email 
        # and phone of the person).
        # 
        # Args:
        # 
        # api_key -- str, a valid API key (use "samplekey" for experimenting).
        #            Note that you can set a default API key 
        #            (PiplApi::SearchApi.default_api_key = '<your_key>') instead of 
        #            passing it to each request object. 
        # first_name -- unicode, minimum 2 chars.
        # middle_name -- unicode. 
        # last_name -- unicode, minimum 2 chars.
        # raw_name -- unicode, an unparsed name containing at least a first name 
        #             and a last name.
        # email -- unicode.
        # phone -- int/long. If a unicode/str is passed instead then it'll be 
        #          striped from all non-digit characters and converted to int.
        #          IMPORTANT: Currently only US/Canada phones can be searched by
        #          so country code is assumed to be 1, phones with different 
        #          country codes are considered invalid and will be ignored.
        # username -- unicode, minimum 4 chars.
        # country -- unicode, a 2 letter country code from:
        #            http://en.wikipedia.org/wiki/ISO_3166-2
        # state -- unicode, a state code from:
        #          http://en.wikipedia.org/wiki/ISO_3166-2%3AUS
        #          http://en.wikipedia.org/wiki/ISO_3166-2%3ACA
        # city -- unicode.
        # raw_address -- unicode, an unparsed address.
        # from_age -- int.
        # to_age -- int.
        # person -- A PiplApi::Person object (available at containers.rb).
        #           The person can contain every field allowed by the data-model
        #           (fields.rb) and can hold multiple fields of 
        #           the same type (for example: two emails, three addresses etc.)
        # query_params_mode -- str, one of "and"/"or" (default "and").
        #                      Advanced parameter, use only if you care about the 
        #                      value of record.query_params_match in the response 
        #                      records.
        #                      Each record in the response has an attribute 
        #                      "query_params_match" which indicates whether the 
        #                      record has the all fields from the query or not.
        #                      When set to "and" all query params are required in 
        #                      order to get query_params_match=True, when set to 
        #                      "or" it's enough that the record has at least one
        #                      of each field type (so if you search with a name 
        #                      and two addresses, a record with the name and one 
        #                      of the addresses will have query_params_match=true)
        # exact_name -- bool (default false).
        #               If set to True the names in the query will be matched 
        #               "as is" without compensating for nicknames or multiple
        #               family names. For example "Jane Brown-Smith" won't return 
        #               results for "Jane Brown" in the same way "Alexandra Pitt"
        #               won't return results for "Alex Pitt".
        # 
        # Each of the arguments that should have a unicode value accepts both 
        # unicode objects and utf8 encoded str (will be decoded automatically).

        fparams = { :query_params_mode => 'and', :exact_name => false }.merge(params)

        if not(fparams[:person].nil?)
            person = fparams[:person]
        else
            person = PiplApi::Person.new()
        end
            
        if fparams[:first_name] || fparams[:middle_name] || fparams[:last_name]
            name = Name.new({:first=>fparams[:first_name], :middle=>fparams[:middle_name], :last=>fparams[:last_name]})
            person.add_fields([name])
        end
        
        person.add_fields([PiplApi::Name.new({:raw=>fparams[:raw_name]})]) unless fparams[:raw_name].nil?
        person.add_fields([PiplApi::Email.new({:address=>fparams[:email]})]) unless fparams[:email].nil?

        if not(fparams[:phone].nil?)
            if fparams[:phone].is_a?(String)
                person.add_fields([PiplApi::Phone.from_text(fparams[:phone])])
            else
                person.add_fields([PiplApi::Phone.new({:number=>fparams[:phone]})])
            end
        end
        
        person.add_fields([PiplApi::Username.new({:content=>fparams[:username]})]) unless fparams[:username].nil?

        if fparams[:country] || fparams[:state] || fparams[:city]
            address = PiplApi::Address.new({:country=>fparams[:country], :state=>fparams[:state], :city=>fparams[:city]})
            person.add_fields([address])
        end
        
        person.add_fields([PiplApi::Address.new({:raw=>fparams[:raw_address]})]) unless fparams[:raw_address].nil?

        if fparams[:from_age] || fparams[:to_age]
            dob = PiplApi::DOB.from_age_range(fparams[:from_age] || 0, fparams[:to_age] || 1000)
            person.add_fields([dob])
        end
        
        @api_key = fparams[:api_key]
        @person = person
        @query_params_mode = fparams[:query_params_mode]
        @exact_name = fparams[:exact_name]
        @_filter_records_by = []
        @_prioritize_records_by = []
    end
    
    def self._prepare_filtering_params(params={})
        # Transform the params to the API format, return a list of params.
        
        if not([nil, true].include?(params[:query_params_match]))
            raise ArgumentError, 'query_params_match can only be `True`'
        end

        if not([nil, true].include?(params[:query_person_match]))
            raise ArgumentError, 'query_person_match can only be `True`'
        end
        
        outparams = []
        (outparams <<= 'domain:%s' % [params[:domain]]) unless params[:domain].nil?

        if not(params[:category].nil?)
            Source.validate_categories([params[:category]])
            outparams <<= 'category:%s' % [params[:category]]
        end

        (outparams <<= 'sponsored_source:%s' % [params[:sponsored_source]]) unless params[:sponsored_source].nil?        
        (outparams <<= 'query_params_match') unless params[:query_params_match].nil?        
        (outparams <<= 'query_person_match') unless params[:query_person_match].nil?        
        
        params[:has_fields] = params[:has_fields] || []
        (params[:has_fields] <<= params[:has_field]) unless params[:has_field].nil?
        # Make sure we only take the class name for the string
        params[:has_fields].keep_if{ |x| x.inspect.scan("::").length > 0 }
        params[:has_fields].each{ |x| outparams <<= 'has_field:%s' % [ x.inspect.split("::")[1] ] }

        outparams
    end    
        
    def add_records_filter(params={})
        # Add a new "and" filter for the records returned in the response.
        # 
        # IMPORTANT: This method can be called multiple times per request for 
        # adding multiple "and" filters, each of these "and" filters is 
        # interpreted as "or" with the other filters.
        # For example:
        # 
        # require 'search'
        # require 'data/fields'
        # request = PiplApi::SearchAPIRequest.new({ :api_key => 'samplekey',
        #                                                            :username => 'eric123' })
        # request.add_records_filter({ :domain => 'linkedin',
        #                                        :has_fields => [PiplApi::Phone] })
        # request.add_records_filter({ :has_fields => [PiplApi::Phone, PiplApi::Job] })
        # 
        # The above request is only for records that are:
        # (from LinkedIn AND has a phone) OR (has a phone AND has a job).
        # Records that don't match this rule will not come back in the response.
        # 
        # Please note that in case there are too many results for the query, 
        # adding filters to the request can significantly improve the number of
        # useful results; when you define which records interest you, you'll
        # get records that would have otherwise be cut-off by the limit on the
        # number of records per query.
        # 
        # Args:
        # 
        # domain -- str, for example "linkedin.com", you may also use "linkedin"
        #           but note that it'll match "linkedin.*" and "*.linkedin.*" 
        #           (any sub-domain and any TLD).
        # category -- str, any one of the categories defined in
        #             PiplAPI::Source::CATEGORIES.
        # sponsored_source -- bool, true means you want just the records that 
        #                     come from a sponsored source and False means you 
        #                     don't want these records.
        # has_fields -- A list of fields classes from fields.rb,
        #               records must have content in all these fields.
        #               For example: [PiplApi::Name, PiplApi::Phone] means you only want records 
        #               that has at least one name and at least one phone.
        # query_params_match -- true is the only possible value and it means you 
        #                       want records that match all the params you passed 
        #                       in the query.
        # query_person_match -- true is the only possible value and it means you
        #                       want records that are the same person you 
        #                       queried by (only records with 
        #                       query_person_match == 1.0, see the documentation 
        #                       of record.query_person_match for more details).
        # 
        # ArgumentError is raised in any case of an invalid parameter.

        filtering_params = SearchAPIRequest._prepare_filtering_params(params)
        if not(filtering_params.nil?)
            @_filter_records_by <<= filtering_params.join(' AND ')
        end
    end
    
    def append_priority_rule(params={})
        # Append a new priority rule for the records returned in the response.
        # 
        # IMPORTANT: This method can be called multiple times per request for 
        # adding multiple priority rules, each call can be with only one argument
        # and the order of the calls matter (the first rule added is the highest 
        # priority, the second is second priority etc).
        # For example:
        # 
        # require 'search'
        # require 'fields'
        # request = PiplApi::SearchAPIRequest.new({ :api_key => 'samplekey',
        #                                                            :username => 'eric123' })
        # request.append_priority_rule({ :domain => 'linkedin' })
        # request.append_priority_rule({ :has_field => PiplApi::Phone })
        # 
        # In the response to the above request records from LinkedIn will be 
        # returned before records that aren't from LinkedIn and records with 
        # phone will be returned before records without phone. 
        # 
        # Please note that in case there are too many results for the query,
        # adding priority rules to the request does not only affect the order 
        # of the records but can significantly improve the number of useful 
        # results; when you define which records interest you, you'll get records
        # that would have otherwise be cut-off by the limit on the number
        # of records per query.  
        # 
        # Args:
        # 
        # domain -- str, for example "linkedin.com", "linkedin" is also possible 
        #           and it'll match "linkedin.*".
        # category -- str, any one of the categories defined in
        #             piplapis.data.source.Source.categories.
        # sponsored_source -- bool, True will bring the records that 
        #                     come from a sponsored source first and False 
        #                     will bring the non-sponsored records first.
        # has_fields -- A field class from fields.rb.
        #               For example: has_field=PiplApi::Phone means you want to give 
        #               a priority to records that has at least one phone.
        # query_params_match -- True is the only possible value and it means you 
        #                       want to give a priority to records that match all 
        #                       the params you passed in the query.
        # query_person_match -- True is the only possible value and it means you
        #                       want to give a priority to records with higher
        #                       query_person_match (see the documentation of 
        #                       record.query_person_match for more details).
        #              
        # ArgumentError is raised in any case of an invalid parameter.

        priority_params = SearchAPIRequest._prepare_filtering_params(params)
        if priority_params.length > 1
            raise ArgumentError, 'The function should be called with one argument'
        end
        if not(priority_params.nil?)
            @_prioritize_records_by <<= priority_params[0]
        end
    end


    def validate_query_params(strict=true)
        # Check if the request is valid and can be sent, raise ArgumentError if 
        # not.
        # 
        # `strict` is a boolean argument that defaults to true which means an 
        # exception is raised on every invalid query parameter, if set to false
        # an exception is raised only when the search request cannot be performed
        # because required query params are missing.

        if (@api_key.nil? or @api_key.length == 0) and SearchApi.default_api_key.nil?
            raise ArgumentError, 'API key is missing'
        end
        
        if not(@person.is_searchable?)
            raise ArgumentError, 'No valid name/username/phone/email in request'
        end
        
        if strict
            if not([nil, 'and', 'or'].include?(@query_params_mode))
                raise ArgumentError, 'query_params_match should be one of "and"/"or"'
            end
            
            unsearchable = @person.unsearchable_fields
            if not(unsearchable.nil?) and (unsearchable.length > 0)
                raise ArgumentError, 'Some fields are unsearchable: %s'  % [unsearchable]
            end
        end
    end
        
    def url
        # The URL of the request (str).
        query = {
            'key' => @api_key || SearchApi.default_api_key,
            'person' => @person.to_json(),
            'query_params_mode' => @query_params_mode,
            'exact_name' => @exact_name,
            'prioritize_records_by' => @_prioritize_records_by.join(','),
            'filter_records_by' => @_filter_records_by,
        }

        self.class::BASE_URL + URI.encode_www_form(query)
    end
    
    def send(strict_validation=true)
        # Send the request and return the response or raise SearchAPIError.
        # 
        # Calling this method blocks the program until the response is returned,
        # if you want the request to be sent asynchronously please refer to the 
        # send_async method. 
        # 
        # The response is returned as a SearchAPIResponse object
        # Also raises an SearchAPIError object in case of an error
        # 
        # `strict_vailidation` is a bool argument that's passed to the 
        # validate_query_params method.
        # 
        # Example:
        # 
        # require 'search'
        # request = SearchAPIRequest.new({ :api_key => 'samplekey',
        #                                                 :email => 'eric@cartman.com' })
        # begin
        #   response = request.send()
        #   # All good!
        #  rescue PiplApi::SearchAPIError => e
        #   puts e
        #  end

        validate_query_params(strict_validation)
        
        uri = URI(url)
        req = Net::HTTP::Get.new(uri.request_uri)
        self.class::HEADERS.keys.each do |key|
            req[key] = self.class::HEADERS[key]
        end

        begin
            response = Net::HTTP.new(uri.host, uri.port).start do |http|
                http.request(req)
            end
            
            if response.is_a? Net::HTTPSuccess
                return SearchAPIResponse.from_json(response.body)
            else
                raise SearchAPIError.from_json(response.body)
            end
        rescue Net::HTTPBadResponse => e
            puts e
        end
    end
    
    def send_async(callback, strict_validation=true)
       # Same as send() but in a non-blocking way.
       # 
       # Use this method if you want to send the request asynchronously so your 
       # program can do other things while waiting for the response.
       # 
       # `callback` is a function (or other callable) with the following 
       # signature:
       # callback(params={ :response, :error })
       # 
       # Example:
       # 
       # require_relative 'search'
       # 
       # request = PiplApi::SearchAPIRequest.new({ :api_key => 'samplekey',
       #                                                            :email => 'eric@cartman.com' })
       # 
       #                                                  
       # my_func = lambda do |params|
       #     if params.keys.include? :response
       #         puts 'I got a response! (%s)' % [ params[:response] ]
       #      else
       #         puts 'I got an exception! (%s)' % [ params[:error] ]
       #     end
       # end
       #                                                  
       # request.send_async(my_func)
       # do_other_things()

        Thread.new do
            begin
                response = send(strict_validation)
                callback.call({:response=>response})
            rescue Exception => msg
                callback.call({:error=>msg})
            end
        end
    end
end


class SearchAPIResponse
    # A response from Pipl's Search API.
    # 
    # A response comprises the two things returned as a result to your query:
    # 
    # - A person (piplapis.data.containers.Person) that is the deta object 
    #   representing all the information available for the person you were 
    #   looking for.
    #   This object will only be returned when our identity-resolution engine is
    #   convinced that the information is of the person represented by your query.
    #   Obviously, if the query was for "John Smith" there's no way for our
    #   identity-resolution engine to know which of the hundreds of thousands of
    #   people named John Smith you were referring to, therefore you can expect
    #   that the response will not contain a person object.
    #   On the other hand, if you search by a unique identifier such as email or
    #   a combination of identifiers that only lead to one person, such as
    #   "Eric Cartman, Age 22, From South Park, CO, US", you can expect to get 
    #   a response containing a single person object.
    # 
    # - A list of records (piplapis.data.containers.Record) that fully/partially 
    #   match the person from your query, if the query was for "Eric Cartman from 
    #   Colorado US" the response might also contain records of "Eric Cartman 
    #   from US" (without Colorado), if you need to differentiate between records 
    #   with full match to the query and partial match or if you want to get a
    #   score on how likely is that record to be related to the person you are
    #   searching please refer to the record's attributes 
    #   record.query_params_match and record.query_person_match.
    # 
    # The response also contains the query as it was interpreted by Pipl. This 
    # part is useful for verification and debugging, if some query parameters 
    # were invalid you can see in response.query that they were ignored, you can 
    # also see how the name/address from your query were parsed in case you 
    # passed raw_name/raw_address in the query.
    # 
    # In some cases when the query isn't focused enough and can't be matched to 
    # a specific person, such as "John Smith from US", the response also contains 
    # a list of suggested searches. This is a list of Record objects, each of 
    # these is an expansion of the original query, giving additional query 
    # parameters so the you can zoom in on the right person.
    
    include Serializable
    
    attr_reader :query, :person, :records, :suggested_searches, :warnings
    
    def initialize(params={})
        # Args:
        # 
        # query -- A Person object with the query as interpreted by Pipl.
        # person -- A Person object with data about the person in the query.
        # records -- A list of Record objects with full/partial match to the 
        #            query.
        # suggested_searches -- A list of Record objects, each of these is an 
        #                       expansion of the original query, giving additional
        #                       query parameters to zoom in on the right person.
        # warnings_ -- A list of unicodes. A warning is returned when the query 
        #             contains a non-critical error and the search can still run.

        @query = params[:query]
        @person = params[:person]
        @records = params[:records] || []
        @suggested_searches = params[:suggested_searches] || []
        @warnings = params[:warnings_] || []
    end
        
    def query_params_matched_records
        # Records that match all the params in the query."""
        @records.keep_if{ |rec| rec.query_params_match}
    end
    
    def query_person_matched_records
        # Records that match the person from the query.
        # 
        # Note that the meaning of "match the person from the query" means "Pipl 
        # is convinced that these records hold data about the person you're 
        # looking for". 
        # Remember that when Pipl is convinced about which person you're looking 
        # for, the response also contains a Person object. This person is 
        # created by merging all the fields and sources of these records. 

        @records.keep_if{ |rec| rec.query_person_match == 1.0 }
    end
        
    def group_records(key_function)
        # Return a dict with the records grouped by the key returned by 
        # `key_function`.
        # 
        # `key_function` takes a record and returns the value from the record to
        # group by (see examples in the group_records_by_* methods below).
        # 
        # The return value is a dict, a key in this dict is a key returned by
        # `key_function` and the value is a list of all the records with this key.

        @records.group_by{ |x| key_function.call(x) }
    end
    
    def group_records_by_domain
        # Return the records grouped by the domain they came from.
        # 
        # The return value is a dict, a key in this dict is a domain
        # and the value is a list of all the records with this domain.

        key_function = Proc.new { |rec| rec.source.domain }
        group_records key_function
    end
    
    def group_records_by_category
        # Return the records grouped by the category of their source.
        # 
        # The return value is a dict, a key in this dict is a category
        # and the value is a list of all the records with this category.

        key_function = Proc.new { |rec| rec.source.category }
        group_records key_function
    end
    
    def group_records_by_query_params_match
        # Return the records grouped by their query_params_match attribute.
        # 
        # The return value is a dict, a key in this dict is a query_params_match
        # bool (so the keys can be just True or False) and the value is a list 
        # of all the records with this query_params_match value.

        key_function = Proc.new { |rec| rec.query_params_match }
        group_records key_function
    end
    
    def group_records_by_query_person_match
        # Return the records grouped by their query_person_match attribute.
        # 
        # The return value is a dict, a key in this dict is a query_person_match
        # float and the value is a list of all the records with this 
        # query_person_match value.

        key_function = Proc.new { |rec| rec.query_person_match }
        group_records key_function
    end
    
    def self.from_dict(d)
        # Transform the dict to a response object and return the response.
        warnings_ = d['warnings'] || []
        query = (d['query'] || {}).empty? ? nil : d['query']
        if not(query.nil?)
            query = Person.from_dict(query)
        end
        person = (d['person'] || {}).empty? ? nil : d['person']
        if not(person.nil?)
            person = Person.from_dict(person)
        end
        records = d['records']
        if not(records.nil?)
            records = records.map{ |rec| Record.from_dict(rec) }
        end
        suggested_searches = d['suggested_searches']
        if not(suggested_searches.nil?)
            suggested_searches = suggested_searches.map{ |rec| Record.from_dict(rec) }
        end
        
        SearchAPIResponse.new({ :query => query,
                                            :person => person,
                                            :records => records,
                                            :suggested_searches => suggested_searches,
                                            :warnings_ => warnings_ })
    end
    
    def to_dict
        # Return a dict representation of the response.
        d = {}
        d['warnings'] = @warnings unless @warnings.nil?
        d['query'] = @query.to_dict unless @query.nil?
        d['person'] = @person.to_dict unless @person.nil?
        
        if not(@records.nil?)
            d['records'] = @records.map{ |rec| rec.to_dict() }
        end

        if not(@suggested_searches.nil?)
            d['suggested_searches'] = @suggested_searches.map{ |rec| rec.to_dict() }
        end
        d
    end
end


class SearchAPIError < APIError
    
    # An exception raised when the response from the search API contains an 
    # error.
    
end

end
