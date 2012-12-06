# coding: UTF-8

module PiplApi

require_relative 'data/utils'

class APIError < Exception
    
    # An exception raised when the response from the API contains an error.
    
    include Serializable
    
    def initialize(error, http_status_code)
        # Extend Exception.__init___ and set two extra attributes - 
        # error (unicode) and http_status_code (int).
        super error
        @error = error
        @http_status_code = http_status_code
    end
    
    def is_user_error?
        # A bool that indicates whether the error is on the user's side.
        (400..499).member?(@http_status_code)
    end
    
    def is_pipl_error?
        # A bool that indicates whether the error is on Pipl's side.
        not(is_user_error?)
    end
    
    def self.from_dict(d)
        # Transform the dict to a error object and return the error.
        self.new(d['error'], d['@http_status_code'])
    end
    
    def to_dict
        # Return a dict representation of the error.
        { 'error' => @error, '@http_status_code' => @http_status_code }
    end
end

end