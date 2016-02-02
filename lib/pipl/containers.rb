require_relative 'fields'
require_relative 'utils'


module Pipl

  class FieldsContainer

    CLASS_CONTAINER = {
        Name: 'names',
        Address: 'addresses',
        Phone: 'phones',
        Email: 'emails',
        Job: 'jobs',
        Education: 'educations',
        Image: 'images',
        Username: 'usernames',
        UserID: 'user_ids',
        Url: 'urls',
        Ethnicity: 'ethnicities',
        Language: 'languages',
        OriginCountry: 'origin_countries',
        Relationship: 'relationships',
        Tag: 'tags',
    }

    attr_reader :names, :addresses, :phones, :emails, :jobs, :educations, :images, :usernames, :user_ids, :urls
    attr_reader :relationships, :tags, :ethnicities, :languages, :origin_countries, :dob, :gender

    def initialize(params={})
      @names = []
      @addresses = []
      @phones = []
      @emails = []
      @jobs = []
      @educations = []
      @images = []
      @usernames = []
      @user_ids = []
      @urls = []
      @ethnicities = []
      @languages = []
      @origin_countries = []
      @relationships = []
      @tags = []
      @dob = nil
      @gender = nil

      add_fields params[:fields] if params.key? :fields
    end

    def self.from_hash(h)
      raise AbstractMethodInvoked.new
    end

    def self.fields_from_hash(h)
      fields = self::CLASS_CONTAINER.map do |cls_name, container|
        cls = Pipl.const_get cls_name
        h[container.to_sym].map { |x| cls.from_hash(x) } if h.key? container.to_sym
      end
                   .flatten.compact
      fields << DOB.from_hash(h[:dob]) if h.key? :dob
      fields << Gender.from_hash(h[:gender]) if h.key? :gender
      fields
    end

    def fields_to_hash
      h = {}
      h[:dob] = @dob.to_hash if @dob
      h[:gender] = @gender.to_hash if @gender
      self.class::CLASS_CONTAINER.values.each do |container|
        fields = instance_variable_get("@#{container}")
        h[container.to_sym] = fields.map { |field| field.to_hash }.compact unless fields.empty?
      end
      h.reject { |_, value| value.nil? or (value.kind_of?(Array) and value.empty?) }
    end

    def add_fields(fields)
      fields.each { |f| add_field f }
    end

    def add_field(field)
      cls_sym = field.class.name.split('::').last.to_sym
      container = self.class::CLASS_CONTAINER[cls_sym]
      if container
        instance_variable_get("@#{container}") << field
      elsif cls_sym == :DOB
        @dob = field
      elsif cls_sym == :Gender
        @gender = field
      else
        raise ArgumentError.new("Object of type #{field.class} is an invalid field")
      end
    end

    def all_fields
      fields = self.class::CLASS_CONTAINER.values.map { |container| instance_variable_get("@#{container}") }
                   .flatten.compact
      fields << @dob if @dob
      fields << @gender if @gender
      fields
    end

    def job
      @jobs.first unless @jobs.empty?
    end

    def address
      @addresses.first unless @addresses.empty?
    end

    def education
      @educations.first unless @educations.empty?
    end

    def language
      @languages.first unless @languages.empty?
    end

    def ethnicity
      @ethnicities.first unless @ethnicities.empty?
    end

    def origin_country
      @origin_countries.first unless @origin_countries.empty?
    end

    def phone
      @phones.first unless @phones.empty?
    end

    def email
      @emails.first unless @emails.empty?
    end

    def name
      @names.first unless @names.empty?
    end

    def image
      @images.first unless @images.empty?
    end

    def url
      @urls.first unless @urls.empty?
    end

    def username
      @usernames.first unless @usernames.empty?
    end

    def user_id
      @user_ids.first unless @user_ids.empty?
    end

    def relationship
      @relationships.first unless @relationships.empty?
    end

  end


  class Relationship < FieldsContainer

    CLASS_CONTAINER = FieldsContainer::CLASS_CONTAINER.clone
    CLASS_CONTAINER.delete :Relationship

    # @!attribute valid_since
    #   @see Field
    # @!attribute inferred
    #   @see Field
    # @!attribute type
    #   @return [String] Type of association of this relationship to a person.
    #   Possible values are:
    #     friend
    #     family
    #     work
    #     other
    # @!attribute subtype
    #   @return [String] Subtype of association of this relationship to a person. Free text.

    attr_accessor :valid_since, :inferred, :type, :subtype

    def initialize(params={})
      super params
      @valid_since = params[:valid_since]
      @inferred = params[:inferred]
      @type = params[:type]
      @subtype = params[:subtype]
    end

    def self.from_hash(h)
      params = Pipl::Field.base_params_from_hash h
      params[:subtype] = h[:@subtype]
      params[:fields] = self.fields_from_hash(h)
      self.new(params)
    end

    def to_hash
      fields_to_hash
    end

    def to_s
      @names.first.to_s unless @names.empty?
    end

  end


  class Source < FieldsContainer

    attr_reader :match, :name, :category, :origin_url, :sponsored, :domain, :source_id, :person_id, :premium, :valid_since

    def initialize(params={})
      super params
      @name = params[:name]
      @category = params[:category]
      @origin_url = params[:origin_url]
      @domain = params[:domain]
      @source_id = params[:source_id]
      @person_id = params[:person_id]
      @sponsored = params[:sponsored]
      @premium = params[:premium]
      @match = params[:match]
      @valid_since = params[:valid_since]
    end

    def self.from_hash(h)
      params = {
          name: h[:@name],
          category: h[:@category],
          origin_url: h[:@origin_url],
          domain: h[:@domain],
          source_id: h[:@id],
          person_id: h[:@person_id],
          match: h[:@match],
          sponsored: h[:@sponsored],
          premium: h[:@premium],
      }
      params[:valid_since] = Pipl::Utils.str_to_date(h[:@valid_since]) if h.key? :@valid_since
      params[:fields] = self.fields_from_hash(h)
      self.new(params)
    end

  end

  class Person < FieldsContainer

    attr_reader :id, :match, :search_pointer

    def initialize(params={})
      super params
      @id = params[:id]
      @match = params[:match]
      @search_pointer = params[:search_pointer]
    end

    def self.from_hash(h)
      params = {
          id: h[:@id],
          match: h[:@match],
          search_pointer: h[:@search_pointer],
      }
      params[:fields] = fields_from_hash(h)
      self.new(params)
    end

    def to_hash
      h = {}
      h[:search_pointer] = @search_pointer if @search_pointer and not @search_pointer.empty?
      h.update(fields_to_hash)
      h
    end

    def is_searchable?
      not @search_pointer.nil? or
          @names.any? { |f| f.is_searchable? } or
          @emails.any? { |f| f.is_searchable? } or
          @phones.any? { |f| f.is_searchable? } or
          @usernames.any? { |f| f.is_searchable? }
    end

    def unsearchable_fields
      all_fields.reject { |f| f.is_searchable? }
    end

  end

end
