# coding: UTF-8

module PiplApi

require_relative 'utils'
require 'date'
require 'set'


class Field
    
    # Base class of all data fields, made only for inheritance.
    
    include Serializable
    
    ATTRIBUTES = []
    CHILDREN = []
    
    def selfclass
        (class << self; self; end)
    end
    
    def initialize(params={})
        @valid_since = params[:valid_since]
        
        # Define getters/setters for all attributes and children
        (self.class::ATTRIBUTES + self.class::CHILDREN).compact.each do |meth|
            selfclass.send(:define_method, meth) { instance_variable_get("@#{meth}") }
            selfclass.send(:define_method, meth + '=') do |value|
                # Make sure that if val is a string, it's utf-8
                if (value.is_a? String) and not(value.encoding.name == "UTF-8")
                    value = PiplApi::to_utf8(value)
                end
                if (meth == 'type')
                    validate_type(value)
                end
                instance_variable_set("@#{meth}", value)
            end
        end
    end
    
    def inspect
        # Return a string representation of the object.
        attrs = (self.class::ATTRIBUTES + self.class::CHILDREN).compact + ['valid_since']
        
        attr_values = Hash[attrs.map{|x| [x, instance_variable_get("@#{x}")] }]
        final_values = attr_values.keys.select{ |x| defined? attr_values[x] and not(attr_values[x].nil?) }

        args = final_values.map{ |x| '%s=%s' % [ x, attr_values[x].inspect ] }
        
        '%s(%s)' % [ self.class.name, args.join(', ') ]
    end

    def ==(other)
        # Bool, indicates whether `self` and `other` have exactly the same data.
        other.instance_of?(self.class) and (inspect == other.inspect)
    end
    
    alias_method :eql?, :==
    
    def validate_type(type)
        # Take an str/unicode `type` and raise an ArgumentError if it's not 
        # a valid type for the object.
        
        # A valid type for a field is a value from the types_set attribute of 
        # that field's class.

        if (not defined? self.class::TYPES_SET) or (not(type is.nil?) and not(self.class::TYPES_SET.include? type))
            raise ArgumentError, 'Invalid type for #{self.class.name} #{type}'
        end
    end

    def self.from_dict(d)
        # Transform the dict to a field object and return the field.
        newdict = {}

        d.each do |key, val|
            next if key.start_with?('display')
            key = key[1..-1] if key.start_with?('@')
            val = PiplApi::str_to_datetime(val) if key == 'valid_since'
            val = DateRange.from_dict(val) if key == 'date_range'
            newdict[key.to_sym] = val
        end
        self.new newdict
    end    

    def to_dict
        # Return a dict representation of the field.
        d = {}
        if (defined? @valid_since) and not(@valid_since.nil?)
            d['@valid_since'] = PiplApi::datetime_to_str(@valid_since)
        end
        
        self.class::ATTRIBUTES.map{|x| [ '@', x ]}.concat(self.class::CHILDREN.map{|x| [ '', x ]}).each do |prefix,key|
            value = instance_variable_get("@#{key}")
            if value.respond_to? :to_dict
                value = value.to_dict
            end
            if not value.nil?
                d[prefix + key] = value
            end
        end

        if self.respond_to? :show
            d['display'] = show
        end
        d
    end

end


class Name < Field
    
    #A name of a person.
    
    ATTRIBUTES = ['type']
    CHILDREN = ['prefix', 'first', 'middle', 'last', 'suffix', 'raw']
    TYPES_SET = Set.new(['present', 'maiden', 'former', 'alias'])
    
    def initialize(params={})
        # `prefix`, `first`, `middle`, `last`, `suffix`, `raw`, `type`, 
        # should all be unicode objects or utf8 encoded strs (will be decoded 
        # automatically).
        # 
        # `raw` is an unparsed name like "Eric T Van Cartman", usefull when you 
        # want to search by name and don't want to work hard to parse it.
        # Note that in response data there's never name.raw, the names in 
        # the response are always parsed, this is only for querying with 
        # an unparsed name.
        # 
        # `type` is one of Name.types_set.
        # 
        # `valid_since` is a DateTime object, it's the first time Pipl's
        # crawlers found this data on the page.

        super params
        @prefix = params[:prefix]
        @first = params[:first]
        @middle = params[:middle]
        @last = params[:last]
        @suffix = params[:suffix]
        @raw = params[:raw]
        @type = params[:type]
    end

    def show
        #A unicode value with the object's data, to be used for displaying 
        # the object in your application.
        vals = [ @prefix, @first, @middle, @last, @suffix ]
        
        disp = vals.select{|v| not v.nil?}.join(' ')
        
        if disp.length == 0
            disp = @raw
        end
        
        if disp.nil?
            disp = ''
        end
        
        PiplApi::to_utf8 disp
    end

    def is_searchable?
        # A bool value that indicates whether the name is a valid name to 
        # search by.
        first = PiplApi::alpha_chars(@first || '')
        last = PiplApi::alpha_chars(@last || '')
        raw = PiplApi::alpha_chars(@raw || '')
        (first.length >= 2 and last.length >= 2) or raw.length >= 4
    end
end    
    

class Address < Field
    
    # An address of a person.
    
    ATTRIBUTES = ['type']
    CHILDREN = ['country', 'state', 'city', 'po_box', 
                'street', 'house', 'apartment', 'raw']
    TYPES_SET = Set.new(['home', 'work', 'old'])
    
    def initialize(params={})
        # `country`, `state`, `city`, `po_box`, `street`, `house`, `apartment`, 
        # `raw`, `type`, should all be unicode objects or utf8 encoded strs 
        # (will be decoded automatically).
        # 
        # `country` and `state` are country code (like "US") and state code 
        # (like "NY"), note that the full value is available as 
        # address.country_full and address.state_full.
        # 
        # `raw` is an unparsed address like "123 Marina Blvd, San Francisco, 
        # California, US", usefull when you want to search by address and don't 
        # want to work hard to parse it.
        # Note that in response data there's never address.raw, the addresses in 
        # the response are always parsed, this is only for querying with 
        # an unparsed address.
        # 
        # `type` is one of Address.types_set.
        # 
        # `valid_since` is a DateTime object, it's the first time Pipl's
        # crawlers found this data on the page.     

        super params
        @country = params[:country]
        @state = params[:state]
        @city = params[:city]
        @po_box = params[:po_box]
        @street = params[:street]
        @house = params[:house]
        @apartment = params[:apartment]
        @raw = params[:raw]
        @type = params[:type]
    end
    
    def show
        # A unicode value with the object's data, to be used for displaying 
        # the object in your application.
        country = not(@state.nil?) ? @country : country_full
        state = not(@city.nil?) ? @state : state_full

        vals = [ @street, @city, state, country ]
        
        disp = vals.select{|v| not v.nil?}.join(', ')
        
        if not(@street.nil?) and (not(@house.nil?) or not(@apartment.nil?))
            prefix = [ @house, @apartment ].select{|v| not (v.nil? or v.length == 0)}.join('-')
            disp = prefix + ' ' + (disp || '')
        end
        if not(@po_box.nil?) and @street.nil?
            disp = "P.O. Box #{po_box} " + (disp || '')
        end
        disp
    end
            
    def is_searchable?
        # A bool value that indicates whether the address is a valid address 
        # to search by.
        
        not(@raw.nil?) or (is_valid_country? and (@state.nil? or is_valid_state?))
    end
    
    def is_valid_country?
        # A bool value that indicates whether the object's country is a valid 
        # country code.
        not(@country.nil?) and COUNTRIES.has_key?(@country.upcase)
    end
    
    def is_valid_state?
        # A bool value that indicates whether the object's state is a valid 
        # state code.
        is_valid_country? and STATES.has_key?(@country.upcase) and
        not(@state.nil?) and STATES[@country.upcase].has_key?(@state.upcase)
    end
    
    def country_full
        # unicode, the full name of the object's country.
        
        # address = PiplApi::Address.new({ :country => 'FR' })
        # address.country
        # => "FR"
        # address.country_full
        # => "France"

        if not(@country.nil?)
            COUNTRIES[@country.upcase]
        end
    end
    
    def state_full
        # The full name of the object's state.
        
        # address = PiplApi::Address.new({ :country => 'US', :state => 'CO' })
        # address.state
        # => "CO"
        # address.state_full
        # => "Colorado"
    
        if is_valid_state?
            STATES[@country.upcase][@state.upcase]
        end
    end
end

class Phone < Field
    
    # A phone number of a person.
    
    ATTRIBUTES = ['type']
    CHILDREN = ['country_code', 'number', 'extension', 'display', 'display_international']
    TYPES_SET = Set.new(['mobile', 'home_phone', 'home_fax', 'work_phone', 
                     'work_fax', 'pager'])
    
    def initialize(params={})
        # `country_code`, `number` and `extension` should all be int/long.
        # `type` is one of PiplApi::Phone::TYPES_SET.
        # `valid_since` is a DateTime object, it's the first time Pipl's
        # crawlers found this data on the page.

        super params
        @country_code = params[:country_code]
        @number = params[:number]
        @extension = params[:extension]
        @type = params[:type]
        # The two following display attributes are available when working with 
        # a response from the API, both hold unicode values that can be used to 
        # display the phone in your application.
        # Note that in other fields the display attribute is a property, this 
        # is not the case here since generating the display for a phone is 
        # country specific and requires a special library.
        @display = ''
        @display_international = ''
    end    
        
    def is_searchable?
        # A bool value that indicates whether the phone is a valid phone 
        # to search by.
        not(@number.nil?) and (@country_code.nil? or @country_code == 1)
    end
    
    def self.from_text(text)
        # Strip `text` (unicode/str) from all non-digit chars and return a new
        # Phone object with the number from text.
        
        # phone = PiplApi::Phone.from_text('(888) 777-666')
        # phone.number
        # => 888777666

        number = text.tr('^0-9','').to_i
        Phone.new({:number=>number})
    end

    def self.from_dict(d)
        # Extend Field.from_dict, set display/display_international 
        # attributes.
        phone = super(d)
        phone.display = d['display'] || ''
        phone.display_international = d['display_international'] || ''
        phone
    end   

    def to_dict
        # Extend Field.to_dict, take the display_international attribute.
        d = super
        if not(@display_international.nil?)
            d['display_international'] = @display_international
        end
        d
    end
end
        
class Email < Field
    # An email address of a person with the md5 of the address, might come
    # in some cases without the address itself and just the md5 (for privacy 
    # reasons).
    
    ATTRIBUTES = ['type']
    CHILDREN = ['address', 'address_md5']
    TYPES_SET = Set.new(['personal', 'work'])
    RE_EMAIL = Regexp.new('^[\w.%\-+]+@[\w.%\-]+\.[a-zA-Z]{2,6}$')
    
    def initialize(params={})
        # `address`, `address_md5`, `type` should be unicode objects or utf8 
        # encoded strs (will be decoded automatically).
        # `type` is one of PiplApi::Email::TYPES_SET.
        # `valid_since` is a DateTime object, it's the first time Pipl's
        # crawlers found this data on the page.

        super params
        @address = params[:address]
        @address_md5 = params[:address_md5]
        @type = params[:type]
    end
    
    def is_valid_email?
        # A bool value that indicates whether the address is a valid 
        # email address.
        
        not(@address.nil?) and not(self.class::RE_EMAIL.match(@address).nil?)
    end
    
    def is_searchable?
        # A bool value that indicates whether the email is a valid email 
        # to search by.
        is_valid_email?
    end
    
    def username
        # unicode, the username part of the email or None if the email is 
        # invalid.
        
        # email = PiplApi::Email.new({ :address => 'eric@cartman.com' })
        # email.username
        # => "eric"
        
        if is_valid_email?
            @address.split('@')[0]
        end
    end
    
    def domain
        # unicode, the domain part of the email or None if the email is 
        # invalid.
        
        # email = PiplApi::Email.new({ :address => 'eric@cartman.com' })
        # email.domain
        # => "cartman.com"
        
        if is_valid_email?
            @address.split('@')[1]
        end
    end
end    
        
class Job < Field
    
    # Job information of a person.
    
    CHILDREN = ['title', 'organization', 'industry', 'date_range']

    def initialize(params={})
        # `title`, `organization`, `industry`, should all be unicode objects 
        # or utf8 encoded strs (will be decoded automatically).
        # `date_range` is A DateRange object (PiplApi::DateRange), 
        # that's the time the person held this job.
        # `valid_since` is a DateTime object, it's the first time Pipl's
        # crawlers found this data on the page. 

        super params
        @title = params[:title]
        @organization = params[:organization]
        @industry = params[:industry]
        @date_range = params[:date_range]
    end
    
    def show
        # A unicode value with the object's data, to be used for displaying 
        # the object in your application.
        if not(@title.nil?) and not(@organization.nil?)
            disp = @title + ' at ' + @organization
        else
            disp = @title || @organization || nil
        end
        
        if (defined? disp) and not(disp.nil?) and not(@industry.nil?)
            if not(@date_range.nil?)
                range = @date_range.years_range
                disp += ' (%s, %d-%d)' % [@industry, range[0], range[1]]
            else
                disp += ' (%s)' % [@industry]
            end
        else
            disp = ((disp || '') + ' ' + (@industry || '')).strip
            if disp.length > 0 and not(@date_range.nil?)
                range = @date_range.years_range
                disp += ' (%d-%d)' % [ range[0], range[1] ]
            end
        end
        disp
    end
end


class Education < Field
    
    # Education information of a person.
    
    CHILDREN = ['degree', 'school', 'date_range']
    
    def initialize(params={})
        # `degree` and `school` should both be unicode objects or utf8 encoded 
        # strs (will be decoded automatically).
        # `date_range` is A DateRange object (PiplApi::DateRange), 
        # that's the time the person was studying.
        # `valid_since` is a DateTime object, it's the first time Pipl's
        # crawlers found this data on the page.

        super params
        @degree = params[:degree]
        @school = params[:school]
        @date_range = params[:date_range]
    end
    
    def show
        # A unicode value with the object's data, to be used for displaying 
        # the object in your application.
        if not(@degree.nil?) and not(@school.nil?)
            disp = @degree + ' from ' + @school
        else
            disp = @degree || @school || nil
        end
        
        if not(disp.nil?) and not(@date_range.nil?)
            range = @date_range.years_range
            disp += ' (%d-%d)' % [ range[0], range[1] ]
        end
        disp || ''
    end
end


class Image < Field
    
    # A URL of an image of a person.
    
    CHILDREN = ['url']
    
    def initialize(params={})
        # `url` should be a unicode object or utf8 encoded str (will be decoded 
        # automatically).
        
        # `valid_since` is a DateTime object, it's the first time Pipl's
        # crawlers found this data on the page.

        super params
        @url = params[:url]
    end
    
    def is_valid_url?
        # A bool value that indicates whether the image URL is a valid URL.
        not(@url.nil?) and PiplApi::is_valid_url?(@url)
    end
end
    

class Username < Field
    # A username/screen-name associated with the person.
    
    # Note that even though in many sites the username uniquely identifies one 
    # person it's not guarenteed, some sites allow different people to use the 
    # same username.

    CHILDREN = ['content']

    def initialize(params={})
        # `content` is the username itself, it should be a unicode object or 
        # a utf8 encoded str (will be decoded automatically).
        
        # `valid_since` is a DateTime object, it's the first time Pipl's
        # crawlers found this data on the page.

        super params
        @content = params[:content]
    end
    
    def is_searchable?
        # A bool value that indicates whether the username is a valid username 
        # to search by.
        st = @content || ''
        PiplApi::alnum_chars(st).length >= 4
    end
end


class UserID < Field
    
    # An ID associated with a person.
    
    # The ID is a string that's used by the site to uniquely identify a person, 
    # it's guaranteed that in the site this string identifies exactly one person.
    
    CHILDREN = ['content']
    
    def initialize(params={})
        # `content` is the ID itself, it should be a unicode object or a utf8 
        # encoded str (will be decoded automatically).
        
        # `valid_since` is a DateTime object, it's the first time Pipl's
        # crawlers found this data on the page.

        super params
        @content = params[:content]
    end
end
      

class DOB < Field
    
    # Date-of-birth of A person.
    # Comes as a date-range (the exact date is within the range, if the exact 
    # date is known the range will simply be with start=end).
    
    CHILDREN = ['date_range']

    def initialize(params={})
        # `date_range` is A DateRange object (PiplApi::DateRange), 
        # the date-of-birth is within this range.
        
        # `valid_since` is a DateTime object, it's the first time Pipl's
        # crawlers found this data on the page.

        super params
        @date_range = params[:date_range]
    end
    
    def show
        # A unicode value with the object's data, to be used for displaying 
        # the object in your application.
        
        # Note: in a DOB object the display is the estimated age.
        
        PiplApi::to_utf8(age.to_s)
    end
    
    def is_searchable?
        not(@date_range.nil?)
    end
    
    def age
        # int, the estimated age of the person.
        
        # Note that A DOB object is based on a date-range and the exact date is 
        # usually unknown so for age calculation the the middle of the range is 
        # assumed to be the real date-of-birth. 

        if not(@date_range.nil?)
            dob = @date_range.middle
            today = Date.today
            
            diff = today.year - dob.year
            diff = diff - 1 if (
                dob.month > today.month or
                (dob.month >= today.month and dob.day > today.day)
            )
            diff
        end
    end

    def age_range
        # An array of two ints - the minimum and maximum age of the person.
        if @date_range.nil?
            return [ nil, nil ]
        end
        start_date = DateRange.new(@date_range.start, @date_range.start)
        end_date = DateRange.new(@date_range.end, @date_range.end)
        start_age = DOB.new({:date_range=>start_date}).age
        end_age = DOB.new({:date_range=>end_date}).age
        [ end_age, start_age ]
    end

    def self.from_birth_year(birth_year)
        # Take a person's birth year (int) and return a new DOB object 
        # suitable for him.
        (raise ArgumentError, 'birth_year must be positive') unless birth_year > 0
            
        date_range = DateRange.from_years_range(birth_year, birth_year)
        DOB.new({:date_range=>date_range})
    end
    
    def self.from_birth_date(birth_date)
        # Take a person's birth date (Date) and return a new DOB 
        # object suitable for him.
        (raise ArgumentError, 'birth_date can\'t be in the future') unless birth_date <= Date.today
        date_range = DateRange.new(birth_date, birth_date)
        DOB.new({:date_range=>date_range})
    end
        
    def self.from_age(age)
        # Take a person's age (int) and return a new DOB object 
        # suitable for him.
        DOB.from_age_range(age, age)
    end
    
    def self.from_age_range(start_age, end_age)
        # Take a person's minimal and maximal age and return a new DOB object 
        # suitable for him.
        
        (raise ArgumentError, 'start_age and end_age can\'t be negative') unless start_age >= 0 and end_age >= 0
        
        if start_age > end_age
            start_age, end_age = end_age, start_age
        end
        
        today = Date.today
        
        start_date = ( today << ((end_age)*12) )
        start_date = start_date - 1
        end_date = today << (start_age*12)
        
        date_range = DateRange.new(start_date, end_date)
        DOB.new({:date_range=>date_range})
    end
end


class RelatedURL < Field
    
    # A URL that's related to a person (blog, personal page in the work 
    # website, profile in some other website).
    
    # IMPORTANT: This URL is NOT the origin of the data about the person, it's 
    # just an extra piece of information available on him.
    
    ATTRIBUTES = ['type']
    CHILDREN = ['content']
    TYPES_SET = Set.new(['personal', 'work', 'blog'])
    
    def initialize(params={})
        # `content` is the URL address itself, both content and type should 
        # be unicode objects or utf8 encoded strs (will be decoded automatically).
        # `type` is one of PiplApi::RelatedURL::TYPES_SET.
        # `valid_since` is a DateTime object, it's the first time Pipl's
        # crawlers found this data on the page.

        super params
        @content = params[:content]
        @type = params[:type]
    end
        
    def is_valid_url?
        # A bool value that indicates whether the URL is a valid URL.
        not(@content.nil?) and PiplApi::is_valid_url?(@content)
    end
end
        

class Relationship < Field
    
    # Name of another person related to this person.
    
    ATTRIBUTES = ['type', 'subtype']
    CHILDREN = ['name']
    TYPES_SET = Set.new(['friend', 'family', 'work', 'other'])
    
    def initialize(params={})
        # `name` is a Name object (PiplApi::Name).
        # 
        # `type` and `subtype` should both be unicode objects or utf8 encoded 
        # strs (will be decoded automatically).
        # 
        # `type` is one of PiplApi::RelatedURL::TYPES_SET.
        # 
        # `subtype` is not restricted to a specific list of possible values (for 
        # example, if type is "family" then subtype can be "Father", "Mother", 
        # "Son" and many other things).
        # 
        # `valid_since` is a DateTime object, it's the first time Pipl's
        # crawlers found this data on the page.

        super params
        @name = params[:name]
        @type = params[:type]
        @subtype = params[:subtype]
    end

    def self.from_dict(d)
        # Extend Field.from_dict and also load the name from the dict.
        relationship = super(d)
        if not(relationship.name.nil?)
            relationship.name = Name.from_dict(relationship.name)
        end
        relationship
    end
end
        

class Tag < Field
    # A general purpose element that holds any meaningful string that's 
    # related to the person.
    # Used for holding data about the person that either couldn't be clearly 
    # classified or was classified as something different than the available
    # data fields.
    
    ATTRIBUTES = ['classification']
    CHILDREN = ['content']
    
    def initialize(params={})
        # `content` is the tag itself, both `content` and `classification` 
        # should be unicode objects or utf8 encoded strs (will be decoded 
        # automatically).
        
        # `valid_since` is a DateTime object, it's the first time Pipl's
        # crawlers found this data on the page.

        super params
        @content = params[:content]
        @classification = params[:classification]
    end
end
    

class DateRange
    
    # A time intervel represented as a range of two dates.
    # DateRange objects are used inside DOB, Job and Education objects.
    
    include Serializable
    
    attr_reader :start, :end
    
    def initialize(start, end_)
        # `start` and `end` are datetime.date objects, both are required.
        
        # For creating a DateRange object for an exact date (like if exact 
        # date-of-birth is known) just pass the same value for `start` and `end`.

        @start = start
        @end = end_
        
        (raise ArgumentError, 'Start/End parameters missing') unless not(@start.nil?) and not(@end.nil?)
        if @start > @end
            @start, @end = @end, @start
        end
    end
    
    def inspect
        # Return a representation of the object.
        return 'DateRange(%s, %s)' % [ @start, @end ]
    end

    def ==(other)
        #"Bool, indicates whether `self` and `other` have exactly the same data.
        other.instance_of?(self.class) and (inspect == other.inspect)
    end
    
    alias_method :eql?, :==

    def is_exact?
        # True if the object holds an exact date (start=end), 
        # False otherwise.
        @start == @end
    end
    
    def middle
        # The middle of the date range (a datetime.date object).
        @start + ((@end - @start) / 2)
    end
    
    def years_range
        # A tuple of two ints - the year of the start date and the year of the 
        # end date.
        [ @start.year, @end.year ]
    end
    
    def self.from_years_range(start_year, end_year)
        # Transform a range of years (two ints) to a DateRange object.
        start_ = Date.new(start_year, 1 , 1)
        end_ = Date.new(end_year, 12 , 31)
        DateRange.new(start_, end_)
    end

    def self.from_dict(d)
        # Transform the dict to a DateRange object.
        start_ = d['start']
        end_ = d['end']
        
        (raise ArgumentError, 'DateRange must have both start and end') unless not(start_.nil?) and not(end_.nil?)
            
        start_ = PiplApi::str_to_date(start_)
        end_ = PiplApi::str_to_date(end_)
        DateRange.new(start_, end_)
    end
    
    def to_dict
        # Transform the date-range to a dict.
        d = {}
        d['start'] = PiplApi::date_to_str(@start)
        d['end'] = PiplApi::date_to_str(@end)
        d
    end
end

end
