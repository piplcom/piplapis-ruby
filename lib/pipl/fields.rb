require 'date'
require 'set'
require_relative 'consts'
require_relative 'utils'

module Pipl

  class Field

    include Pipl::Utils

    attr_accessor :valid_since, :last_seen, :inferred, :current

    def initialize(params={})
      @valid_since = params[:valid_since]
      @last_seen = params[:last_seen]
      @inferred = params[:inferred]
      @current = params[:current]
    end

    def self.from_hash(h)
      params = base_params_from_hash h
      extra_metadata.each { |p| params[p] = h["@#{p}".to_sym] }
      params = h.merge params
      self.new(params)
    end

    def self.base_params_from_hash(h)
      params = {
          inferred: h[:@inferred],
          current: h[:@current],
          type: h[:@type],
          display: h[:display]
      }
      params[:valid_since] = Date.strptime(h[:@valid_since], Pipl::DATE_FORMAT) if h.key? :@valid_since
      params[:last_seen] = Date.strptime(h[:@last_seen], Pipl::DATE_FORMAT) if h.key? :@last_seen
      params[:date_range] = Pipl::DateRange.from_hash(h[:date_range]) if h.key? :date_range
      params
    end

    def self.extra_metadata
      []
    end

    def to_hash

    end

    def is_searchable?
      true
    end

  end


  class Name < Field
    # @!attribute first
    #   @return [String] First name
    # @!attribute middle
    #   @return [String] Middle name or initial
    # @!attribute last
    #   @return [String] Last name
    # @!attribute prefix
    #   @return [String] Name prefix
    # @!attribute suffix
    #   @return [String] Name suffix
    # @!attribute type
    #   @return [String] Type of association of this name to a person. One of `present`, `maiden`, `former` or `alias`.

    attr_accessor :first, :middle, :last, :prefix, :suffix, :type, :raw, :display

    def initialize(params={})
      super params
      @first = params[:first]
      @middle = params[:middle]
      @last = params[:last]
      @prefix = params[:prefix]
      @suffix = params[:suffix]
      @type = params[:type]
      @raw = params[:raw]
      @display = params[:display]
    end

    def to_hash
      {first: @first, middle: @middle, last: @last, prefix: @prefix, suffix: @suffix, raw: @raw}
          .reject { |_, value| value.nil? }
    end

    def is_searchable?
      first = Pipl::Utils.alpha_chars(@first || '')
      last = Pipl::Utils.alpha_chars(@last || '')
      raw = Pipl::Utils.alpha_chars(@raw || '')
      (first.length > 1 and last.length > 1) or raw.length > 3
    end

    def to_s
      return @display if @display

      vals = [@prefix, @first, @middle, @last, @suffix]
      s = vals.any? ? vals.select { |v| v }.map { |v| v.capitalize }.join(' ') : nil
      s ? Pipl::Utils.to_utf8(s) : ''
    end

  end


  class Address < Field
    # @!attribute country
    #   @return [String] 2 letters country code
    # @!attribute state
    #   @return [String] 2 letters state code
    # @!attribute city
    #   @return [String] City
    # @!attribute street
    #   @return [String] Street
    # @!attribute house
    #   @return [String] House
    # @!attribute apartment
    #   @return [String] Apartment
    # @!attribute zip_code
    #   @return [String] Zip Code
    # @!attribute po_box
    #   @return [String] Post Office box number
    # @!attribute type
    #   @return [String] Type of association of this address to a person. One of `home`, `work` or `old`.
    # @!attribute raw
    #   @return [String] Unparsed address.
    # @!attribute display
    #   @return [String] well formatted representation of this address for display purposes.

    attr_accessor :country, :state, :city, :street, :house, :apartment, :zip_code, :po_box, :type, :raw, :display

    def initialize(params={})
      super params
      @country = params[:country]
      @state = params[:state]
      @city = params[:city]
      @street = params[:street]
      @house = params[:house]
      @apartment = params[:apartment]
      @zip_code = params[:zip_code]
      @po_box = params[:po_box]
      @type = params[:type]
      @raw = params[:raw]
      @display = params[:display]
    end

    def is_valid_country?
      @country and Pipl::COUNTRIES.key? @country.upcase.to_sym
    end

    def is_valid_state?
      is_valid_country? and Pipl::STATES.key?(@country.upcase.to_sym) and
          @state and Pipl::STATES[@country.upcase.to_sym].key?(@state.upcase.to_sym)
    end

    def to_hash
      {country: @country, state: @state, city: @city, street: @street, house: @house, apartment: @apartment,
       zip_code: @zip_code, po_box: @po_box, raw: @raw}
          .reject { |_, value| value.nil? }
    end

    def is_searchable?
      [@raw, @country, @state, @city].any? {|x| x and not x.empty?}
    end

    def country_full
      Pipl::COUNTRIES[@country.upcase.to_sym] if @country
    end

    def state_full
      Pipl::STATES[@country.upcase.to_sym][@state.upcase.to_sym] if is_valid_state?
    end

    def to_s
      return @display if @display

      country = @state ? @country : country_full
      state = @city ? @state : state_full
      vals = [@street, @city, state, country]
      s = vals.any? ? vals.select { |v| v }.join(', ') : ''

      if @street and (@house or @apartment)
        prefix = [@house, @apartment].select { |v| v and not v.empty? }.join('-')
        s = prefix + ' ' + (s || '')
      end

      if @po_box and @street.nil?
        s = "P.O. Box #{@po_box} " + (s || '')
      end

      s ? Pipl::Utils.to_utf8(s) : ''
    end

  end


  class Phone < Field
    # @!attribute country_code
    #   @return [Fixnum] International country calling code
    # @!attribute number
    #   @return [Fixnum] Actual phone number
    # @!attribute extension
    #   @return [String] Office extension
    # @!attribute type
    #   @return [String] Type of association of this phone to a person.
    #   Possible values are:
    #     mobile
    #     home_phone
    #     home_fax
    #     work_phone
    #     work_fax
    #     pager
    # @!attribute raw
    #   @return [String] Unparsed phone number
    # @!attribute display
    #   @return [String] Well formatted representation of this phone number for display purposes.
    # @!attribute display_international
    #   @return [String] Well formatted international representation of this phone number for display purposes.

    attr_accessor :country_code, :number, :extension, :type, :raw, :display, :display_international

    def initialize(params={})
      super params
      @country_code = params[:country_code]
      @number = params[:number]
      @extension = params[:extension]
      @type = params[:type]
      @raw = params[:raw]
      @display = params[:display]
      @display_international = params[:display_international]
    end

    def self.extra_metadata
      [:display_international]
    end

    def to_hash
      {country_code: @country_code, number: @number, extension: @extension, raw: @raw}
          .reject { |_, value| value.nil? }
    end

    def is_searchable?
      (@raw and not @raw.empty?) or not @number.nil?
    end

  end


  class Email < Field

    RE_EMAIL = Regexp.new('^[\w.%\-+]+@[\w.%\-]+\.[a-zA-Z]{2,6}$')

    # @!attribute address
    #   @return [String] Plain email address
    # @!attribute address_md5
    #   @return [String] MD5 hash of the email address
    # @!attribute type
    #   @return [String] Type of email association to a person. One of `personal` or `work`.
    # @!attribute disposable
    #   @return [Boolean] Indicating if this email comes from a disposable email provider.
    # @!attribute email_provider
    #   @return [Boolean] Indicating if this email comes from a well known email provider like gmail or yahoo.

    attr_accessor :address, :address_md5, :type, :disposable, :email_provider

    def initialize(params={})
      super params
      @address = params[:address]
      @address_md5 = params[:address_md5]
      @type = params[:type]
      @disposable = params[:disposable]
      @email_provider = params[:email_provider]
    end

    def self.extra_metadata
      [:disposable, :email_provider]
    end

    def is_valid_email?
      not RE_EMAIL.match(@address).nil?
    end

    def is_searchable?
      is_valid_email? or (not @address_md5.nil? and @address_md5.length == 32)
    end

    def to_hash
      {address: @address, address_md5: @address_md5}.reject { |_, value| value.nil? }
    end

    def username
      @address.split('@')[0] if is_valid_email?
    end

    def domain
      @address.split('@')[1] if is_valid_email?
    end

  end


  class Job < Field

    attr_accessor :title, :organization, :industry, :date_range, :display

    def initialize(params={})
      super params
      @title = params[:title]
      @organization = params[:organization]
      @industry = params[:industry]
      @date_range = params[:date_range]
      @display = params[:display]
    end

    def to_hash
      {title: @title, organization: @organization, industry: @industry,
       date_range: @date_range ? @date_range.to_hash : nil}
          .reject { |_, value| value.nil? }
    end

    def to_s
      return @display if @display

      if @title and @organization
        s = @title + ' at ' + @organization
      else
        s = @title || @organization
      end

      if s and @industry
        if @date_range
          range = @date_range.years_range
          s += ' (%s, %d-%d)' % [@industry, range[0], range[1]]
        else
          s += ' (%s)' % [@industry]
        end
      else
        s = ((s || '') + ' ' + (@industry || '')).strip
        if s and @date_range
          range = @date_range.years_range
          s += ' (%d-%d)' % [range[0], range[1]]
        end
      end

      s ? Pipl::Utils.to_utf8(s) : ''
    end

  end


  class Education < Field

    attr_accessor :degree, :school, :date_range, :display

    def initialize(params={})
      super params
      @degree = params[:degree]
      @school = params[:school]
      @date_range = params[:date_range]
      @display = params[:display]
    end

    def to_hash
      {degree: @degree, school: @school, date_range: @date_range ? @date_range.to_hash : nil}
          .reject { |_, value| value.nil? }
    end

    def to_s
      return @display if @display

      if @degree and @school
        s = @degree + ' from ' + @school
      else
        s = @degree || @school
      end

      if s and @date_range
        range = @date_range.years_range
        s += ' (%d-%d)' % [range[0], range[1]]
      end

      s ? Pipl::Utils.to_utf8(s) : ''
    end

  end


  class Image < Field

    attr_accessor :url, :thumbnail_token

    def initialize(params={})
      super params
      @url = params[:url]
      @thumbnail_token = params[:thumbnail_token]
    end

    def thumbnail_url(params={})
      return unless @thumbnail_token

      opts = {width: 100, height: 100, favicon: true, zoom_face: true, use_https: false}.merge(params)
      schema = opts.delete(:use_https) ? 'https': 'http'
      query_params = ["token=#{@thumbnail_token}"] + opts.map { |k, v| "#{k}=#{v}" unless v.nil? }
      "#{schema}://thumb.pipl.com/image?#{query_params.compact.join('&')}"
    end

  end


  class Username < Field

    attr_accessor :content

    def initialize(params={})
      super params
      @content = params[:content]
    end

    def to_hash
      {content: @content} if @content
    end

    def is_searchable?
      @content and Pipl::Utils.alnum_chars(@content).length > 3
    end

  end


  class UserID < Username

    def is_searchable?
      false
    end

  end


  class DOB < Field

    attr_accessor :date_range, :display

    def initialize(params={})
      super params
      @date_range = params[:date_range]
      @display = params[:display]
    end

    def self.from_birth_year(birth_year)
      raise ArgumentError.new('birth_year must be positive') unless birth_year > 0
      self.new({date_range: DateRange.from_years_range(birth_year, birth_year)})
    end

    def self.from_birth_date(birth_date)
      raise ArgumentError.new('birth_date can\'t be in the future') unless birth_date <= Date.today
      self.new({date_range: DateRange.new(birth_date, birth_date)})
    end

    def self.from_age(age)
      self.from_age_range(age, age)
    end

    def self.from_age_range(start_age, end_age)
      raise ArgumentError.new('start_age and end_age can\'t be negative') if start_age < 0 or end_age < 0

      if start_age > end_age
        start_age, end_age = end_age, start_age
      end

      today = Date.today
      start_date = today << end_age * 12
      start_date = start_date - 1
      end_date = today << start_age * 12
      self.new({date_range: Pipl::DateRange.new(start_date, end_date)})
    end

    def to_s
      @display or Pipl::Utils.to_utf8(age.to_s)
    end

    def age
      unless @date_range.nil?
        dob = @date_range.middle
        today = Date.today
        diff = today.year - dob.year
        diff = diff - 1 if dob.month > today.month or (dob.month >= today.month and dob.day > today.day)
        diff
      end
    end

    def age_range
      if @date_range
        return [self.age, self.age] unless @date_range.start and @date_range.end
        start_age = DOB.new({date_range: Pipl::DateRange.new(@date_range.start, @date_range.start)}).age
        end_age = DOB.new({date_range: Pipl::DateRange.new(@date_range.end, @date_range.end)}).age
        return end_age, start_age
      else
        return nil, nil
      end
    end

    def to_hash
      {date_range: @date_range.to_hash} if @date_range
    end

    def is_searchable?
      not @date_range.nil?
    end

  end


  class Url < Field
    # @!attribute url
    #   @return [String] Actual Url
    # @!attribute category
    #   @return [String] Category of the domain
    #   Possible values are:
    #     background_reports
    #     contact_details
    #     email_address
    #     media
    #     personal_profiles
    #     professional_and_business
    #     public_records
    #     publications
    #     school_and_classmates
    #     web_pages
    # @!attribute domain
    #   @return [String] Canonical domain of the url
    # @!attribute name
    #   @return [String] Name of the website hosting the url
    # @!attribute sponsored
    #   @return [Boolean] Indicate if this url comes from a sponsored data source
    # @!attribute sponsored
    #   @return [String] Unique identifier of this url

    attr_accessor :url, :category, :domain, :name, :sponsored, :source_id

    def initialize(params={})
      super params
      @url = params[:url]
      @category = params[:category]
      @domain = params[:domain]
      @name = params[:name]
      @sponsored = params[:sponsored]
      @source_id = params[:source_id]
    end

    def self.extra_metadata
      [:category, :domain, :name, :sponsored, :source_id]
    end

  end


  class Gender < Field

    attr_accessor :content

    def initialize(params={})
      super params
      raise ArgumentError.new("#{params[:content]} is not a valid gender") \
      unless %w(male female).include? params[:content]
      @content = params[:content]
    end

    def to_s
      Pipl::Utils.titleize @content if @content
    end

    def to_hash
      {content: @content} if @content
    end

  end


  class Ethnicity < Field

    # @!attribute content
    #   @return [String] Ethnicity name based on the U.S Census Bureau.
    #   Possible values are:
    #     white
    #     black
    #     american_indian
    #     alaska_native
    #     asian_indian
    #     chinese
    #     filipino
    #     other_asian
    #     japanese
    #     korean
    #     vietnamese
    #     native_hawaiian
    #     guamanian
    #     chamorro
    #     samoan
    #     other_pacific_islander
    #     other

    attr_accessor :content

    def initialize(params={})
      super params
      @content = params[:content]
    end

    def to_s
      Pipl::Utils.titleize @content.gsub(/_/, ' ') if @content
    end

  end


  class Language < Field

    attr_accessor :language, :region, :display

    def initialize(params={})
      super params
      @language = params[:language]
      @region = params[:region]
      @display = params[:display]
    end

    def to_s
      return @display if @display
      return "#{@language}_#{@region}" if @language and @region
      return @language if @language and not @language.empty?
      @region
    end

  end


  class OriginCountry < Field

    attr_accessor :country

    def initialize(params={})
      super params
      @country = params[:country]
    end

    def to_s
      Pipl::COUNTRIES[@country.upcase.to_sym] if @country
    end

  end


  class Tag < Field

    attr_accessor :content, :classification

    def initialize(params={})
      super params
      @content = params[:content]
      @classification = params[:classification]
    end

    def self.extra_metadata
      [:classification]
    end

    def to_s
      @content
    end

  end


  class DateRange

    attr_reader :start, :end

    def initialize(start, end_)
      @start = start
      @end = end_
      if @start and @end and @start > @end
        @start, @end = @end, @start
      end
    end

    # def ==(other)
    #   other.instance_of?(self.class) and inspect == other.inspect
    # end
    #
    # alias_method :eql?, :==

    def is_exact?
      @start and @end and @start == @end
    end

    def middle
      @start and @end ? @start + ((@end - @start) / 2) : @start or @end
    end

    def years_range
      [@start.year, @end.year] if @start and @end
    end

    def self.from_years_range(start_year, end_year)
      self.new(Date.new(start_year, 1, 1), Date.new(end_year, 12, 31))
    end

    def self.from_hash(h)
      start_, end_ = h[:start], h[:end]
      initializing_start = start_ ? Date.strptime(start_, Pipl::DATE_FORMAT) : nil
      initializing_end = end_ ? Date.strptime(end_, Pipl::DATE_FORMAT) : nil
      self.new(initializing_start, initializing_end)
    end

    def to_hash
      h = {}
      h[:start] = @start.strftime(Pipl::DATE_FORMAT) if @start
      h[:end] = @end.strftime(Pipl::DATE_FORMAT) if @end
      h
    end
  end

end
