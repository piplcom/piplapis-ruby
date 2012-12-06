# coding: UTF-8

module PiplApi

require 'json'
require 'date'
require 'uri'

STATES = {
    'US'=> {'WA'=> 'Washington', 'VA'=> 'Virginia', 'DE'=> 'Delaware', 'DC'=> 'District Of Columbia', 'WI'=> 'Wisconsin', 'WV'=> 'West Virginia', 'HI'=> 'Hawaii', 'FL'=> 'Florida', 'YT'=> 'Yukon', 'WY'=> 'Wyoming', 'PR'=> 'Puerto Rico', 'NJ'=> 'New Jersey', 'NM'=> 'New Mexico', 'TX'=> 'Texas', 'LA'=> 'Louisiana', 'NC'=> 'North Carolina', 'ND'=> 'North Dakota', 'NE'=> 'Nebraska', 'FM'=> 'Federated States Of Micronesia', 'TN'=> 'Tennessee', 'NY'=> 'New York', 'PA'=> 'Pennsylvania', 'CT'=> 'Connecticut', 'RI'=> 'Rhode Island', 'NV'=> 'Nevada', 'NH'=> 'New Hampshire', 'GU'=> 'Guam', 'CO'=> 'Colorado', 'VI'=> 'Virgin Islands', 'AK'=> 'Alaska', 'AL'=> 'Alabama', 'AS'=> 'American Samoa', 'AR'=> 'Arkansas', 'VT'=> 'Vermont', 'IL'=> 'Illinois', 'GA'=> 'Georgia', 'IN'=> 'Indiana', 'IA'=> 'Iowa', 'MA'=> 'Massachusetts', 'AZ'=> 'Arizona', 'CA'=> 'California', 'ID'=> 'Idaho', 'PW'=> 'Pala', 'ME'=> 'Maine', 'MD'=> 'Maryland', 'OK'=> 'Oklahoma', 'OH'=> 'Ohio', 'UT'=> 'Utah', 'MO'=> 'Missouri', 'MN'=> 'Minnesota', 'MI'=> 'Michigan', 'MH'=> 'Marshall Islands', 'KS'=> 'Kansas', 'MT'=> 'Montana', 'MP'=> 'Northern Mariana Islands', 'MS'=> 'Mississippi', 'SC'=> 'South Carolina', 'KY'=> 'Kentucky', 'OR'=> 'Oregon', 'SD'=> 'South Dakota'},
    'CA'=> {'AB'=> 'Alberta', 'BC'=> 'British Columbia', 'MB'=> 'Manitoba', 'NB'=> 'New Brunswick', 'NT'=> 'Northwest Territories', 'NS'=> 'Nova Scotia', 'NU'=> 'Nunavut', 'ON'=> 'Ontario', 'PE'=> 'Prince Edward Island', 'QC'=> 'Quebec', 'SK'=> 'Saskatchewan', 'YU'=> 'Yukon', 'NL'=> 'Newfoundland and Labrador'},
    'AU'=> {'WA'=> 'State of Western Australia', 'SA'=> 'State of South Australia', 'NT'=> 'Northern Territory', 'VIC'=> 'State of Victoria', 'TAS'=> 'State of Tasmania', 'QLD'=> 'State of Queensland', 'NSW'=> 'State of New South Wales', 'ACT'=> 'Australian Capital Territory'},
    'GB'=> {'WLS'=> 'Wales', 'SCT'=> 'Scotland', 'NIR'=> 'Northern Ireland', 'ENG'=> 'England'}
}

COUNTRIES = {'BD'=> 'Bangladesh', 'WF'=> 'Wallis And Futuna Islands', 'BF'=> 'Burkina Faso', 'PY'=> 'Paraguay', 'BA'=> 'Bosnia And Herzegovina', 'BB'=> 'Barbados', 'BE'=> 'Belgium', 'BM'=> 'Bermuda', 'BN'=> 'Brunei Darussalam', 'BO'=> 'Bolivia', 'BH'=> 'Bahrain', 'BI'=> 'Burundi', 'BJ'=> 'Benin', 'BT'=> 'Bhutan', 'JM'=> 'Jamaica', 'BV'=> 'Bouvet Island', 'BW'=> 'Botswana', 'WS'=> 'Samoa', 'BR'=> 'Brazil', 'BS'=> 'Bahamas', 'JE'=> 'Jersey', 'BY'=> 'Belarus', 'BZ'=> 'Belize', 'RU'=> 'Russian Federation', 'RW'=> 'Rwanda', 'LT'=> 'Lithuania', 'RE'=> 'Reunion', 'TM'=> 'Turkmenistan', 'TJ'=> 'Tajikistan', 'RO'=> 'Romania', 'LS'=> 'Lesotho', 'GW'=> 'Guinea-bissa', 'GU'=> 'Guam', 'GT'=> 'Guatemala', 'GS'=> 'South Georgia And South Sandwich Islands', 'GR'=> 'Greece', 'GQ'=> 'Equatorial Guinea', 'GP'=> 'Guadeloupe', 'JP'=> 'Japan', 'GY'=> 'Guyana', 'GG'=> 'Guernsey', 'GF'=> 'French Guiana', 'GE'=> 'Georgia', 'GD'=> 'Grenada', 'GB'=> 'Great Britain', 'GA'=> 'Gabon', 'GN'=> 'Guinea', 'GM'=> 'Gambia', 'GL'=> 'Greenland', 'GI'=> 'Gibraltar', 'GH'=> 'Ghana', 'OM'=> 'Oman', 'TN'=> 'Tunisia', 'JO'=> 'Jordan', 'HR'=> 'Croatia', 'HT'=> 'Haiti', 'SV'=> 'El Salvador', 'HK'=> 'Hong Kong', 'HN'=> 'Honduras', 'HM'=> 'Heard And Mcdonald Islands', 'AD'=> 'Andorra', 'PR'=> 'Puerto Rico', 'PS'=> 'Palestine', 'PW'=> 'Pala', 'PT'=> 'Portugal', 'SJ'=> 'Svalbard And Jan Mayen Islands', 'VG'=> 'Virgin Islands, British', 'AI'=> 'Anguilla', 'KP'=> 'North Korea', 'PF'=> 'French Polynesia', 'PG'=> 'Papua New Guinea', 'PE'=> 'Per', 'PK'=> 'Pakistan', 'PH'=> 'Philippines', 'PN'=> 'Pitcairn', 'PL'=> 'Poland', 'PM'=> 'Saint Pierre And Miquelon', 'ZM'=> 'Zambia', 'EH'=> 'Western Sahara', 'EE'=> 'Estonia', 'EG'=> 'Egypt', 'ZA'=> 'South Africa', 'EC'=> 'Ecuador', 'IT'=> 'Italy', 'AO'=> 'Angola', 'KZ'=> 'Kazakhstan', 'ET'=> 'Ethiopia', 'ZW'=> 'Zimbabwe', 'SA'=> 'Saudi Arabia', 'ES'=> 'Spain', 'ER'=> 'Eritrea', 'ME'=> 'Montenegro', 'MD'=> 'Moldova', 'MG'=> 'Madagascar', 'MA'=> 'Morocco', 'MC'=> 'Monaco', 'UZ'=> 'Uzbekistan', 'MM'=> 'Myanmar', 'ML'=> 'Mali', 'MO'=> 'Maca', 'MN'=> 'Mongolia', 'MH'=> 'Marshall Islands', 'US'=> 'United States', 'UM'=> 'United States Minor Outlying Islands', 'MT'=> 'Malta', 'MW'=> 'Malawi', 'MV'=> 'Maldives', 'MQ'=> 'Martinique', 'MP'=> 'Northern Mariana Islands', 'MS'=> 'Montserrat', 'NA'=> 'Namibia', 'IM'=> 'Isle Of Man', 'UG'=> 'Uganda', 'MY'=> 'Malaysia', 'MX'=> 'Mexico', 'IL'=> 'Israel', 'BG'=> 'Bulgaria', 'FR'=> 'France', 'AW'=> 'Aruba', 'AX'=> '\xc3\x85land', 'FI'=> 'Finland', 'FJ'=> 'Fiji', 'FK'=> 'Falkland Islands', 'FM'=> 'Micronesia', 'FO'=> 'Faroe Islands', 'NI'=> 'Nicaragua', 'NL'=> 'Netherlands', 'NO'=> 'Norway', 'SO'=> 'Somalia', 'NC'=> 'New Caledonia', 'NE'=> 'Niger', 'NF'=> 'Norfolk Island', 'NG'=> 'Nigeria', 'NZ'=> 'New Zealand', 'NP'=> 'Nepal', 'NR'=> 'Naur', 'NU'=> 'Niue', 'MR'=> 'Mauritania', 'CK'=> 'Cook Islands', 'CI'=> "C\xc3\xb4te D'ivoire", 'CH'=> 'Switzerland', 'CO'=> 'Colombia', 'CN'=> 'China', 'CM'=> 'Cameroon', 'CL'=> 'Chile', 'CC'=> 'Cocos (keeling) Islands', 'CA'=> 'Canada', 'CG'=> 'Congo (brazzaville)', 'CF'=> 'Central African Republic', 'CD'=> 'Congo (kinshasa)', 'CZ'=> 'Czech Republic', 'CY'=> 'Cyprus', 'CX'=> 'Christmas Island', 'CS'=> 'Serbia', 'CR'=> 'Costa Rica', 'HU'=> 'Hungary', 'CV'=> 'Cape Verde', 'CU'=> 'Cuba', 'SZ'=> 'Swaziland', 'SY'=> 'Syria', 'KG'=> 'Kyrgyzstan', 'KE'=> 'Kenya', 'SR'=> 'Suriname', 'KI'=> 'Kiribati', 'KH'=> 'Cambodia', 'KN'=> 'Saint Kitts And Nevis', 'KM'=> 'Comoros', 'ST'=> 'Sao Tome And Principe', 'SK'=> 'Slovakia', 'KR'=> 'South Korea', 'SI'=> 'Slovenia', 'SH'=> 'Saint Helena', 'KW'=> 'Kuwait', 'SN'=> 'Senegal', 'SM'=> 'San Marino', 'SL'=> 'Sierra Leone', 'SC'=> 'Seychelles', 'SB'=> 'Solomon Islands', 'KY'=> 'Cayman Islands', 'SG'=> 'Singapore', 'SE'=> 'Sweden', 'SD'=> 'Sudan', 'DO'=> 'Dominican Republic', 'DM'=> 'Dominica', 'DJ'=> 'Djibouti', 'DK'=> 'Denmark', 'DE'=> 'Germany', 'YE'=> 'Yemen', 'AT'=> 'Austria', 'DZ'=> 'Algeria', 'MK'=> 'Macedonia', 'UY'=> 'Uruguay', 'YT'=> 'Mayotte', 'MU'=> 'Mauritius', 'TZ'=> 'Tanzania', 'LC'=> 'Saint Lucia', 'LA'=> 'Laos', 'TV'=> 'Tuval', 'TW'=> 'Taiwan', 'TT'=> 'Trinidad And Tobago', 'TR'=> 'Turkey', 'LK'=> 'Sri Lanka', 'LI'=> 'Liechtenstein', 'LV'=> 'Latvia', 'TO'=> 'Tonga', 'TL'=> 'Timor-leste', 'LU'=> 'Luxembourg', 'LR'=> 'Liberia', 'TK'=> 'Tokela', 'TH'=> 'Thailand', 'TF'=> 'French Southern Lands', 'TG'=> 'Togo', 'TD'=> 'Chad', 'TC'=> 'Turks And Caicos Islands', 'LY'=> 'Libya', 'VA'=> 'Vatican City', 'AC'=> 'Ascension Island', 'VC'=> 'Saint Vincent And The Grenadines', 'AE'=> 'United Arab Emirates', 'VE'=> 'Venezuela', 'AG'=> 'Antigua And Barbuda', 'AF'=> 'Afghanistan', 'IQ'=> 'Iraq', 'VI'=> 'Virgin Islands, U.s.', 'IS'=> 'Iceland', 'IR'=> 'Iran', 'AM'=> 'Armenia', 'AL'=> 'Albania', 'VN'=> 'Vietnam', 'AN'=> 'Netherlands Antilles', 'AQ'=> 'Antarctica', 'AS'=> 'American Samoa', 'AR'=> 'Argentina', 'AU'=> 'Australia', 'VU'=> 'Vanuat', 'IO'=> 'British Indian Ocean Territory', 'IN'=> 'India', 'LB'=> 'Lebanon', 'AZ'=> 'Azerbaijan', 'IE'=> 'Ireland', 'ID'=> 'Indonesia', 'PA'=> 'Panama', 'UA'=> 'Ukraine', 'QA'=> 'Qatar', 'MZ'=> 'Mozambique'}

TIMESTAMP_FORMAT = '%Y-%m-%dT%H:%M:%S'
DATE_FORMAT = '%Y-%m-%d'

PIPLAPI_VERSION = '1.0'

module Serializable

    # This module is mixed into every class in the library that needs the ability to
    # be serialized/deserialized to/from a JSON string.
    
    # Every class must implement its own to_dict method that transforms
    # an object to a dict and from_dict method that transforms a dict to 
    # an object.
    
    module ClassMethods
        def from_json(json_str)
            # Deserialize the object from a JSON string.
            d = JSON.load(json_str)
            from_dict(d)
        end
    end
    
    extend ClassMethods
    # So one 'include' will also include class methods
    def self.included(base)
        base.extend(ClassMethods)
    end
    
    def to_json
        # Serialize the object to a JSON string.
        d = to_dict()
        JSON.dump(d)
    end
    
    # Used internally for testing
    def to_hash
        Hash[instance_variables.map { |var| [var[1..-1].to_sym, instance_variable_get(var)] }]
    end
end

def self.str_to_datetime(s)
    # Transform an str object to a datetime object.
    DateTime.strptime(s, TIMESTAMP_FORMAT)
end


def self.datetime_to_str(dt)
    # Transform a datetime object to an str object.
    dt.strftime(TIMESTAMP_FORMAT)
end


def self.str_to_date(s)
    # Transform an str object to a date object.
    Date.strptime(s, DATE_FORMAT)
end
    

def self.date_to_str(d)
    # Transform a date object to an str object.
    d.strftime(DATE_FORMAT)
end


def self.is_valid_url?(url)
    # Return True if `url` (str/unicode) is a valid URL, False otherwise.
    not((url =~ URI::ABS_URI).nil?)
end


def self.alpha_chars(s)
    # Strip all non alphabetic characters from the str/unicode `s`.
    s.gsub(/\p{^Alpha}/, '')
end


def self.alnum_chars(s)
    # Strip all non alphanumeric characters from the str/unicode `s`.
    s.gsub(/\p{^Alnum}/, '')
end


def self.to_utf8(obj)
    # Return str representation of obj, if s is a unicode object it's encoded with utf8.
    if obj.respond_to?(:encode)
        begin
            obj.encode('UTF-8')
            
            rescue Exception
                puts 'Could not convert #{obj} to UTF-8'
                raise
        end
    else
        obj
    end
end

end
