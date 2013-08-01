# coding: UTF-8

module PiplApi

# Ruby wrapper for easily making calls to Pipl's Name API.
# 
# Pipl's Name API provides useful utilities for applications that need to work
# with people names, the utilities include:
# - Parsing a raw name into prefix/first-name/middle-name/last-name/suffix. 
# - Getting the gender that's most common for people with the name.
# - Getting possible nicknames of the name.
# - Getting possible full-names of the name (in case the name is a nick).
# - Getting different spelling options of the name.
# - Translating the name to different languages.
# - Getting the list of most common locations for people with this name.
# - Getting the list of most common ages for people with this name.
# - Getting an estimated number of people in the world with this name.
# 
# The classes contained in this module are:
# - NameAPIRequest -- Build your request and send it.
# - NameAPIResponse -- Holds the response from the API in case it contains data.
# - NameAPIError -- An exception raised when the API response is an error.
# 
# - AltNames -- Used in NameAPIResponse for holding alternative names.
# - LocationStats -- Used in NameAPIResponse for holding location data.
# - AgeStats -- Used in NameAPIResponse for holding age data.

require 'uri'
require 'net/http'

require_relative 'data/utils'
require_relative 'data/fields'
require_relative 'error'

module NameApi
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

class NameAPIRequest
    # A request to Pipl's Name API.
    # 
    # A request is build with a name that can be provided parsed to 
    # first/middle/last (in case it's already available to you parsed) 
    # or unparsed (and then the API will parse it).
    # Note that the name in the request can also be just a first-name or just 
    # a last-name.
    
    attr_reader :name
    
    HEADERS = {'User-Agent' => 'piplapis/ruby/%s' % PiplApi::PIPLAPI_VERSION}
    BASE_URL = 'http://api.pipl.com/name/v2/json/?'
    # HTTPS is also supported:
    #BASE_URL = 'https://api.pipl.com/name/v2/json/?'
    
    def initialize(params={})
        # `api_key` is a valid API key (str), use "samplekey" for 
        # experimenting, note that you can set a default API key
        # (PiplApi::NameApi.default_api_key = '<your_key>') instead of passing it 
        # to each request object.
        # 
        # `first_name`, `middle_name`, `last_name`, `raw_name` should all be 
        # unicode objects or utf8 encoded strs (will be decoded automatically).
        # 
        # ArgumentError is raised in case of illegal parameters.
        # 
        # Examples:
        # 
        # require 'name'
        # request1 = PiplApi::NameAPIRequest.new({ :api_key => 'samplekey',
        #                                                            :first_name => 'Eric',
        #                                                            :last_name => 'Cartman' })
        # request2 = PiplApi::NameAPIRequest.new({ :api_key => 'samplekey',
        #                                                            :last_name => 'Cartman' })
        # request3 = PiplApi::NameAPIRequest.new({ :api_key => 'samplekey',
        #                                                            :raw_name => 'Eric Cartman' })
        # request4 = PiplApi::NameAPIRequest.new({ :api_key => 'samplekey',
        #                                                            :raw_name => 'Eric' })

        if (params[:api_key].nil? or params[:api_key].length == 0) and NameApi.default_api_key.nil?
            raise ArgumentError, 'A valid API key is required'
        end
        
        haveraw = (not(params[:raw_name].nil?) and params[:raw_name].length > 0)
        haveparsed = (not(params[:first_name].nil?) and params[:first_name].length > 0) or
                           (not(params[:middle_name].nil?) and params[:middle_name].length > 0) or
                           (not(params[:last_name].nil?) and params[:last_name].length > 0)
        
        if not(haveraw) and not(haveparsed)
            raise ArgumentError, 'A name is missing'
        end
        
        if haveraw and haveparsed
            raise ArgumentError, 'Name should be provided raw or parsed, not both'
        end
            
        @api_key = params[:api_key]
        @name = Name.new({  :first => params[:first_name],
                                        :middle => params[:middle_name],
                                        :last => params[:last_name], 
                                        :raw => params[:raw_name] })
    end
    
    def url
        # The URL of the request (str).
        query = {
            'key' => PiplApi::to_utf8(@api_key || NameApi.default_api_key),
            'first_name' => PiplApi::to_utf8(@name.first || ''),
            'middle_name' => PiplApi::to_utf8(@name.middle || ''),
            'last_name' => PiplApi::to_utf8(@name.last || ''),
            'raw_name' => PiplApi::to_utf8(@name.raw || '')
        }

        self.class::BASE_URL + URI.encode_www_form(query)
    end
        
    def send
        # Send the request and return the response or raise NameAPIError.
        # 
        # The response is returned as a PiplApi::NameAPIResponse object.
        # 
        # Raises a PiplApi::NameAPIError object in case of error
        # 
        # Example:
        # 
        # require 'name'
        # request = PiplApi::NameAPIRequest.new({ :api_key => 'samplekey',
        #                                                          :raw_name => 'Eric Cartman' })
        # begin
        #   response = request.send()
        #   # All good!
        #  rescue PiplApi::NameAPIError => e
        #   puts e
        #  end

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
                return NameAPIResponse.from_json(response.body)
            else
                raise NameAPIError.from_json(response.body)
            end
        rescue Net::HTTPBadResponse => e
            puts e
        end
    end
end
    
class NameAPIResponse
    # A response from Pipl's search API.
    
    # A response contains the name from the query (parsed), and when available
    # the gender, nicknames, full-names, spelling options, translations, common 
    # locations and common ages for the name. It also contains an estimated 
    # number of people in the world with this name.
    
    include Serializable
    
    attr_reader :name, :gender, :gender_confidence, :full_names, :nicknames, :spellings, :translations, :top_locations
    attr_reader :top_ages, :estimated_world_persons_count, :warnings
    
    def initialize(params={})
        # Args:
        # 
        # name -- A piplapis.data.fields.Name object - the name from the query.
        # gender -- str, "male" or "female".
        # gender_confidence -- float between 0.0 and 1.0, represents how 
        #                     confidence Pipl is that `gender` is the correct one.
        #                     (Unisex names will get low confidence score).
        # full_names -- An AltNames object.
        # nicknames -- An AltNames object.
        # spellings -- An AltNames object.
        # translations -- A dict of language_code -> AltNames object for this 
        #                 language.
        # top_locations -- A list of LocationStats objects.
        # top_ages -- A list of AgeStats objects.
        # estimated_world_persons_count -- int, estimated number of people in the 
        #                                  world with the name from the query.
        # warnings_ -- A list of unicodes. A warning is returned when the query 
        #              contains a non-critical error.

        @name = params[:name] || Name.new()
        @gender = params[:gender]
        @gender_confidence = params[:gender_confidence]
        @full_names = params[:full_names] || AltNames.new()
        @nicknames = params[:nicknames] || AltNames.new()
        @spellings = params[:spellings] || AltNames.new()
        @translations = params[:translations] || {}
        @top_locations = params[:top_locations] || []
        @top_ages = params[:top_ages] || []
        @estimated_world_persons_count = params[:estimated_world_persons_count]
        @warnings = params[:warnings_] || []
    end
        
    def self.from_dict(d)
        # Transform the dict to a response object and return the response.
        name = Name.from_dict(d['name'] || {})
        gender, gender_confidence = d['gender'] || [nil, nil]
        full_names = AltNames.from_dict(d['full_names'] || {})
        nicknames = AltNames.from_dict(d['nicknames'] || {})
        spellings = AltNames.from_dict(d['spellings'] || {})

        translations = {}
        (d['translations'] || {}).each_pair{ |k,v| translations[k] = AltNames.from_dict(v) }
                             
        top_locations = (d['top_locations'] || []).map{ |loc| LocationStats.from_dict(loc) }
        top_ages = (d['top_ages'] || []).map{ |age_stats| AgeStats.from_dict(age_stats) }

        world_count = d['estimated_world_persons_count']
        warnings_ = d['warnings']
        
        
        NameAPIResponse.new({ :name => name,
                                          :gender => gender, 
                                          :gender_confidence => gender_confidence,
                                          :full_names => full_names,
                                          :nicknames => nicknames, 
                                          :spellings => spellings,
                                          :translations => translations, 
                                          :top_locations => top_locations,
                                          :top_ages => top_ages, 
                                          :estimated_world_persons_count => world_count, 
                                          :warnings_ => warnings_ })
    end    
        
    def to_dict
        # Return a dict representation of the response.
        t = {}
        @translations.each_pair{ |k,v| t[k] = v.to_dict }
        
        d = {
            'warnings' => @warnings,
            'name' => @name.to_dict(),
            'gender' => [@gender, @gender_confidence],
            'full_names' => @full_names.to_dict(),
            'nicknames' => @nicknames.to_dict(),
            'spellings' => @spellings.to_dict(),
            'translations' => t,
            'top_locations' => @top_locations.map{ |loc| loc.to_dict },
            'top_ages' => @top_ages.map{ |age_stats| age_stats.to_dict },
            'estimated_world_persons_count' => self.estimated_world_persons_count,
        }
        d
    end
end

class AltNames < Field
    
    # Helper class for NameAPIResponse, holds alternate 
    # first/middle/last names for a name.
    
    CHILDREN = ['first', 'middle', 'last']
    
    def initialize(params={})
        super params
        @first = params[:first] || nil  # list of unicodes
        @middle = params[:middle] || nil  # list of unicodes
        @last = params[:last] || nil  # list of unicodes
    end
end
        

class LocationStats < Address
=begin
    Helper class for NameAPIResponse, holds a location and the estimated 
    percent of people with the name that lives in this location.
    
    Note that this class inherits from Address and therefore has the 
    properties location_stats.country_full, location_stats.state_full and
    location_stats.display.
=end
    
    CHILDREN = ['country', 'state', 'city', 'estimated_percent']
    
    def initialize(params={})
        super params
        @estimated_percent = params[:estimated_percent]  # 0 <= int <= 100
    end
end
        

class AgeStats < Field
    
    # Helper class for NameAPIResponse, holds an age range and the estimated 
    # percent of people with the name that their age is within the range.
    
    CHILDREN = ['from_age', 'to_age', 'estimated_percent']
    
    def initialize(params={})
        super params
        @from_age = params[:from_age]  # int
        @to_age = params[:to_age]  # int
        @estimated_percent = params[:estimated_percent]  # 0 <= int <= 100
    end
end

class NameAPIError < APIError
    
    # An exception raised when the response from the name API contains an 
    # error.
    
end

end
