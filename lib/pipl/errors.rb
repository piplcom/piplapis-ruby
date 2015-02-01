module Pipl

  class AbstractMethodInvoked < StandardError;
  end

  class Client

    class APIError < Exception

      def initialize(error, http_status_code)
        super error
        @error = error
        @http_status_code = http_status_code
      end

      def is_user_error?
        (400..499).member?(@http_status_code)
      end

      def is_pipl_error?
        not is_user_error?
      end

      def self.from_json(json_str)
        h = JSON.load(json_str)
        self.new(h['error'], h['@http_status_code'])
      end

    end

  end

end