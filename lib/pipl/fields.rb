require 'date'
require 'set'
require_relative 'consts'
require_relative 'utils'

module Pipl

  class Field

    include Pipl::Utils

    attr_accessor :valid_since, :inferred

    def initialize(params={})
      @valid_since = params[:valid_since]
      @inferred = params[:inferred]
    end

    def self.from_hash(h)
      params = base_params_from_hash h
      extra_metadata.each { |p| params[p] = h["@#{p}".to_sym] }
      params = h.merge params
      self.new(params)
    end

    def self.base_params_from_hash(h)
      params = {inferred: h[:@inferred], type: h[:@type], display: h[:@display]}
      params[:valid_since] = Date.strptime(h[:@valid_since], Pipl::DATE_FORMAT) if h.key? :@valid_since
      params[:date_range] = Pipl::DateRange.from_hash(h[:date_range]) if h.key? :date_range
      params
    end

    def self.extra_metadata
      []
    end

    def to_hash

    end

    # def validate_type(type)
    #   if (not defined? self.class::TYPES_SET) or (not (type is.nil?) and not (self.class::TYPES_SET.include? type))
    #     raise ArgumentError, "Invalid type for #{self.class.name} #{type}"
    #   end
    # end

    def is_searchable?
      true
    end

  end


  class Name < Field

    TYPES = Set.new(%w(present maiden former alias))

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

    def to_s
      return @display if @display

      vals = [@prefix, @first, @middle, @last, @suffix]
      s = vals.any? ? vals.select { |v| v }.join(' ') : nil
      s ? Pipl::Utils.to_utf8(s) : ''
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

  end


  class Address < Field

    TYPES = Set.new(%w(home work old))

    attr_accessor :country, :state, :city, :po_box, :street, :house, :apartment, :zip_code, :type, :raw, :display

    def initialize(params={})
      super params
      @country = params[:country]
      @state = params[:state]
      @city = params[:city]
      @po_box = params[:po_box]
      @street = params[:street]
      @house = params[:house]
      @apartment = params[:apartment]
      @zip_code = params[:zip_code]
      @type = params[:type]
      @raw = params[:raw]
      @display = params[:display]
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

    def is_valid_country?
      @country and Pipl::COUNTRIES.key? @country.upcase.to_sym
    end

    def is_valid_state?
      is_valid_country? and Pipl::STATES.key?(@country.upcase.to_sym) and
          @state and Pipl::STATES[@country.upcase.to_sym].key?(@state.upcase.to_sym)
    end

    def country_full
      Pipl::COUNTRIES[@country.upcase.to_sym] if @country
    end

    def state_full
      Pipl::STATES[@country.upcase.to_sym][@state.upcase.to_sym] if is_valid_state?
    end

    def to_hash
      {country: @country, state: @state, city: @city, street: @street, house: @house, apartment: @apartment,
       zip_code: @zip_code, po_box: @po_box, raw: @raw}
          .reject { |_, value| value.nil? }
    end

    def is_searchable?
      @raw or (is_valid_country? and (@state.nil? or @state.empty? or is_valid_state?))
    end

  end

  class Phone < Field

    TYPES = Set.new(%w(mobile home_phone home_fax work_phone work_fax pager))

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
      @number or (@raw and not @raw.empty?)
    end

  end

  class Email < Field

    TYPES = Set.new(%w(personal work))
    RE_EMAIL = Regexp.new('^[\w.%\-+]+@[\w.%\-]+\.[a-zA-Z]{2,6}$')

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
      @address and RE_EMAIL.match(@address)
    end

    def is_searchable?
      is_valid_email? || (@address_md5 && @address_md5.length == 32)
    end

    def username
      @address.split('@')[0] if is_valid_email?
    end

    def domain
      @address.split('@')[1] if is_valid_email?
    end

    def to_hash
      {address: @address, address_md5: @address_md5}.reject { |_, value| value.nil? }
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

    def to_s
      return @display if @display

      if @title and @organization
        s = @title + ' at ' + @organization
      else
        s = @title || @organization || nil
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

    def to_hash
      {title: @title, organization: @organization, industry: @industry,
       date_range: @date_range ? @date_range.to_hash : nil}
          .reject { |_, value| value.nil? }
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

    def to_s
      return @display if @display

      if @degree and @school
        s = @degree + ' from ' + @school
      else
        s = @degree || @school || nil
      end

      if s and @date_range
        range = @date_range.years_range
        s += ' (%d-%d)' % [range[0], range[1]]
      end

      s ? Pipl::Utils.to_utf8(s) : ''
    end

    def to_hash
      {degree: @degree, school: @school, date_range: @date_range ? @date_range.to_hash : nil}
          .reject { |_, value| value.nil? }
    end

  end


  class Image < Field

    attr_accessor :url, :thumbnail_token

    def initialize(params={})
      super params
      @url = params[:url]
      @thumbnail_token = params[:thumbnail_token]
    end

    def is_valid_url?
      @url and Pipl::Utils.is_valid_url?(@url)
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

    CATEGORIES = Set.new(%w(background_reports contact_details email_address media personal_profiles
                            professional_and_business public_records publications school_and_classmates web_pages))

    attr_accessor :url, :category, :domain, :name, :sponsored

    def initialize(params={})
      super params
      @url = params[:url]
      @category = params[:category]
      @domain = params[:domain]
      @name = params[:name]
      @sponsored = params[:sponsored]
    end

    def self.extra_metadata
      [:category, :domain, :name, :sponsored]
    end

    def is_valid_url?
      @url and Pipl::Utils.is_valid_url? @url
    end

  end


  class Gender < Field

    TYPES = Set.new(%w(male female))

    attr_accessor :content

    def initialize(params={})
      super params
      raise ArgumentError.new("#{params[:content]} is not a valid gender") unless TYPES.include? params[:content]
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

    TYPES = Set.new(%w(white black american_indian alaska_native asian_indian chinese filipino other_asian japanese
                        korean vietnamese native_hawaiian guamanian chamorro samoan other_pacific_islander other))

    attr_accessor :content

    def initialize(params={})
      super params
      raise ArgumentError.new("#{params[:content]} is not a valid ethnicity") unless TYPES.include? params[:content]
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


  class DateRange

    attr_reader :start, :end

    def initialize(start, end_)
      raise ArgumentError.new('Start/End parameters missing') unless start and end_

      @start = start
      @end = end_
      if @start > @end
        @start, @end = @end, @start
      end
    end

    def ==(other)
      other.instance_of?(self.class) and inspect == other.inspect
    end

    alias_method :eql?, :==

    def is_exact?
      @start == @end
    end

    def middle
      @start + ((@end - @start) / 2)
    end

    def years_range
      return @start.year, @end.year
    end

    def self.from_years_range(start_year, end_year)
      self.new(Date.new(start_year, 1, 1), Date.new(end_year, 12, 31))
    end

    def self.from_hash(h)
      start_, end_ = h[:start], h[:end]
      raise ArgumentError.new('DateRange must have both start and end') unless start_ and end_
      self.new(Date.strptime(start_, Pipl::DATE_FORMAT), Date.strptime(end_, Pipl::DATE_FORMAT))
    end

    def to_hash
      {start: @start.strftime(Pipl::DATE_FORMAT), end: @end.strftime(Pipl::DATE_FORMAT)}
    end
  end

end
