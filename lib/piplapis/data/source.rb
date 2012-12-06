# coding: UTF-8

module PiplApi

require 'set'
require_relative 'fields'
require_relative 'utils'


class Source < Field
    
    # A source of data that's available in a Record/Person object.
    # 
    # The source is simply the URL of the page where the data was found, for 
    # convenience it also contains some meta-data about the data-source (like
    # its full name and the category it belongs to).
    # 
    # Note that this class is a subclass of Field even though a source is not 
    # exactly a data field, it's just because the functionality implemented in 
    # Field is useful here too.
    
    CATEGORIES = Set.new(['background_reports', 'contact_details', 
                      'email_address', 'media', 'personal_profiles', 
                      'professional_and_business', 'public_records', 
                      'publications', 'school_and_classmates', 'web_pages'])
    
    ATTRIBUTES = [ 'is_sponsored' ]
    CHILDREN = [ 'name', 'category', 'url', 'domain' ]
    
    def initialize(params={})
        # `name`, `category`, `url` and `domain` should all be unicode or utf8 
        # encoded strs (will be decoded automatically).
        # 
        # `is_sponsored` is a bool value that indicates whether the source is from 
        # one of Pipl's sponsored sources.
        # 
        # `category` is one of Source.categories. 

        super
        
        @is_sponsored = params[:is_sponsored]
        @name = params[:name]
        @category = params[:category]
        @url = params[:url]
        @domain = params[:domain]

    end
    
    def is_valid_url?
        # A bool that indicates whether the URL is valid.
        not(@url.nil?) and PiplApi::is_valid_url?(@url)
    end
    
    def self.validate_categories(categories)
        # Take an iterable of source categories and raise ValueError if some 
        # of them are invalid.
        invalid = categories.to_a - Source::CATEGORIES.to_a
        
        if invalid.length > 0
            raise ArgumentError, 'Invalid categories: #{invalid}'
        end
    end
end

end
