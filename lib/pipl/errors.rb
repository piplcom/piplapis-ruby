module Pipl

  class AbstractMethodInvoked < StandardError;
  end

  class Client

    class APIError < Exception
      attr_reader :status_code

      def initialize(message, status_code)
        super message
        @status_code = status_code
      end

      def is_user_error?
        (400..499).member?(@status_code)
      end

      def is_pipl_error?
        not is_user_error?
      end

      def self.from_json(json_str)
        h = JSON.parse(json_str, symbolize_names: true)
        self.new(h[:error], h[:@http_status_code])
      end

    end

  end

end