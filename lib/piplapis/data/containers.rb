# coding: UTF-8

module PiplApi

require_relative 'fields'
require_relative 'source'
require_relative 'utils'


class FieldsContainer
    
    # The base class of Record and Person, made only for inheritance.
    
    include Serializable
    
    attr_reader :names, :addresses, :phones, :emails, :jobs, :educations, :images, :usernames
    attr_reader :user_ids, :dobs, :related_urls, :relationships, :tags
    
    CLASS_CONTAINER = {
        PiplApi::Name => 'names', 
        PiplApi::Address => 'addresses', 
        PiplApi::Phone => 'phones', 
        PiplApi::Email => 'emails', 
        PiplApi::Job => 'jobs', 
        PiplApi::Education => 'educations', 
        PiplApi::Image => 'images', 
        PiplApi::Username => 'usernames', 
        PiplApi::UserID => 'user_ids', 
        PiplApi::DOB => 'dobs', 
        PiplApi::RelatedURL => 'related_urls', 
        PiplApi::Relationship => 'relationships', 
        PiplApi::Tag => 'tags'
    }
    
    def initialize(fields=nil)
        # `fields` is an iterable of field objects from 
        # piplapis.data.fields.
        @names = []
        @addresses = []
        @phones = []
        @emails = []
        @jobs = []
        @educations = []
        @images = []
        @usernames = []
        @user_ids = []
        @dobs = []
        @related_urls = []
        @relationships = []
        @tags = []
        
        add_fields(not(fields.nil?) ? fields : [])
    end
    
    def add_fields(fields)
        # Add the fields to their corresponding container.
        # `fields` is an iterable of field objects from fields.rb
        
        fields.each do |field|
           cls = field.class
             
            container = FieldsContainer::CLASS_CONTAINER[cls]
            
            if container.nil?
                raise ArgumentError, "Object of type %s is an invalid field" % [cls]
            else
                instance_variable_get("@#{container}") << field
            end
        end
    end
    
    def all_fields
        # A list with all the fields contained in this object.
        FieldsContainer::CLASS_CONTAINER.values.map{ |val| instance_variable_get("@#{val}") }.flatten
    end

    def self.fields_from_dict(d)
        # Load the fields from the dict, return a list with all the fields.
        
        fields = []
        FieldsContainer::CLASS_CONTAINER.keys.each do |field_cls|
            container = FieldsContainer::CLASS_CONTAINER[field_cls]
            field_dict = d[container]
            if not(field_dict.nil?)
                field_dict.each do |x|
                    fields <<= field_cls.from_dict( x )
                end
            end
        end
        fields
    end

    def fields_to_dict
        # Transform the object to a dict and return the dict.
        d = {}
        FieldsContainer::CLASS_CONTAINER.values.each do |container|
            fields = instance_variable_get("@#{container}")
            if not(fields.nil?)
                allfields = fields.map{ |field| field.to_dict() }
                d[container] = allfields unless allfields.length == 0
            end
        end
        d
    end
end
    
class Record < FieldsContainer
    # A record is all the data available in a specific source. 
    # 
    # Every record object is based on a source which is basically the URL of the 
    # page where the data is available, and the data itself that comes as field
    # objects (Name, Address, Email etc. see piplapis.data.fields).
    # 
    # Each type of field has its own container (note that Record is a subclass 
    # of FieldsContainer).
    # For example:
    # 
    # require 'containers'
    # fields = [PiplApi::Email.new({ :address => 'eric@cartman.com' }), PiplApi::Phone.new({ :number => 999888777 })]
    # record = PiplApi::Record.new({ :fields => fields })
    # record.emails
    # => [PiplApi::Email(address="eric@cartman.com")]
    # record.phones
    # => [PiplApi::Phone(number=999888777, display="", display_international="")]
    # 
    # Records come as results for a query and therefore they have attributes that 
    # indicate if and how much they match the query. They also have a validity 
    # timestamp available as an attribute.
    
    attr_reader :source, :query_params_match, :query_person_match, :valid_since
    
    def initialize(params={})
        # Extend FieldsContainer.initialize and set the record's source
        # and attributes.
        # 
        # Args:
        # 
        # fields -- An iterable of fields (from fields.rb).
        # source -- A Source object (piplapis.data.source.Source).
        # query_params_match -- A bool value that indicates whether the record 
        #                       contains all the params from the query or not.
        # query_person_match -- A float between 0.0 and 1.0 that indicates how 
        #                       likely it is that this record holds data about 
        #                       the person from the query.
        #                       Higher value means higher likelihood, value 
        #                       of 1.0 means "this is definitely him".
        #                       This value is based on Pipl's statistical 
        #                       algorithm that takes into account many parameters
        #                       like the popularity of the name/address (if there 
        #                       was a name/address in the query) etc.
        # valid_since -- A DateTime object, this is the first time 
        #                Pipl's crawlers saw this record.

        super params[:fields]
        @source = params[:source] || Source.new()
        @query_params_match = params[:query_params_match]
        @query_person_match = params[:query_person_match]
        @valid_since = params[:valid_since]
    end
        
    def self.from_dict(d)
        # Transform the dict to a record object and return the record.
        query_params_match = d['@query_params_match']
        query_person_match = d['@query_person_match']
        valid_since = d['@valid_since']
        valid_since = PiplApi::str_to_datetime(valid_since) unless valid_since.nil?
        source = Source.from_dict(d['source'] || {})
        fields = Record.fields_from_dict(d)
        
        Record.new({:source=>source, :fields=>fields, 
                          :query_params_match=>query_params_match, 
                          :query_person_match=>query_person_match, 
                          :valid_since=>valid_since})
    end
        
    def to_dict
        # Return a dict representation of the record.
        d = {}
        
        d['@query_params_match'] = @query_params_match unless @query_params_match.nil?
        d['@query_person_match'] = @query_person_match unless @query_person_match.nil?
        d['@valid_since'] = PiplApi::datetime_to_str(@valid_since) unless @valid_since.nil?
        d['source'] = @source.to_dict unless @source.nil?

        d.update(fields_to_dict)
        d
    end
end

class Person < FieldsContainer
    # A Person object is all the data available on an individual.
    # 
    # The Person object is essentially very similar in its structure to the 
    # Record object, the main difference is that data about an individual can 
    # come from multiple sources while a record is data from one source.
    # 
    # The person's data comes as field objects (Name, Address, Email etc. see 
    # piplapis.data.fields).
    # Each type of field has its on container (note that Person is a subclass 
    # of FieldsContainer).
    # For example:
    # 
    # require 'containers'
    # fields = [PiplApi::Email.new({ :address => 'eric@cartman.com' }), PiplApi::Phone.new({ :number => 999888777 })]
    # person = PiplApi::Person.new({ :fields => fields })
    # person.emails
    # => [PiplApi::Email(address="eric@cartman.com")]
    # person.phones
    # => [PiplApi::Phone(number=999888777, display="", display_international="")]
    # 
    # Note that a person object is used in the Search API in two ways:
    # - It might come back as a result for a query (see PiplApi::SearchAPIResponse).
    # - It's possible to build a person object with all the information you 
    #   already have about the person you're looking for and send this object as 
    #   the query (see SearchAPIRequest).
    
    attr_reader :sources, :query_params_match
    
    def initialize(params={})
        # Extend FieldsContainer.initialize and set the record's sources
        # and query_params_match attribute.
        # 
        # Args:
        # 
        # fields -- An iterable of fields (fields.rb).
        # sources -- A list of Source objects (source.rb).
        # query_params_match -- A bool value that indicates whether the record 
        #                       contains all the params from the query or not.
        
        super params[:fields]
        @sources = params[:sources] || []
        @query_params_match = params[:query_params_match]
    end
    
    def is_searchable?
        # A bool value that indicates whether the person has enough data and
        # can be sent as a query to the API.
        all = @names + @emails + @phones + @usernames
        all.keep_if{ |field| field.is_searchable? }.length > 0
    end
    
    def unsearchable_fields
        # A list of all the fields that can't be searched by.
        
        # For example: names/usernames that are too short, emails that are 
        # invalid etc.
        
        all = @names + @emails + @phones + @usernames + @addresses + @dobs
        all.keep_if{ |field| not(field.is_searchable?) }
    end
        
    def self.from_dict(d)
        # Transform the dict to a person object and return the person.
        query_params_match = d['@query_params_match']
        all_sources = d['sources'] || []
        
        sources = all_sources.map{ |src| Source.from_dict(src) }
        fields = Person.fields_from_dict(d)
        
        Person.new({:fields=>fields, :sources=>sources, :query_params_match=>query_params_match})
    end
        
    def to_dict
        # Return a dict representation of the person.
        d = {}
        
        d['@query_params_match'] = @query_params_match unless @query_params_match.nil?
        
        sources = @sources.nil? ? [] : @sources.map{ |src| src.to_dict() }
        d['sources'] =  sources unless sources.length == 0

        d.update(fields_to_dict())
        d
    end
end

end
