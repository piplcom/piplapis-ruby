module Pipl

  class AbstractMethodInvoked < StandardError;
  end

  class Client

    class APIError < Exception
      attr_reader :status_code
      attr_reader :qps_allotted, :qps_current, :quota_allotted, :quota_current, :quota_reset

      def initialize(message, status_code, params={})
        super message
        @status_code = status_code
        @qps_allotted = params[:qps_allotted]
        @qps_current = params[:qps_current]
        @quota_allotted = params[:quota_allotted]
        @quota_current = params[:quota_current]
        @quota_reset = params[:quota_reset]
      end

      def is_user_error?
        (400..499).member?(@status_code)
      end

      def is_pipl_error?
        not is_user_error?
      end

      def self.deserialize(json_str, headers={})
        h = JSON.parse(json_str, symbolize_names: true)

        # Quota and Throttle headers
        params = {}
        params[:qps_allotted] = headers['X-APIKey-QPS-Allotted'].to_i if headers.key? 'X-APIKey-QPS-Allotted'
        params[:qps_current] = headers['X-APIKey-QPS-Current'].to_i if headers.key? 'X-APIKey-QPS-Current'
        params[:quota_allotted] = headers['X-APIKey-Quota-Allotted'].to_i if headers.key? 'X-APIKey-Quota-Allotted'
        params[:quota_current] = headers['X-APIKey-Quota-Current'].to_i if headers.key? 'X-APIKey-Quota-Current'
        params[:quota_reset] = DateTime.strptime(headers['X-Quota-Reset'], '%A, %B %d, %Y %I:%M:%S %p %Z') if headers.key? 'X-Quota-Reset'

        self.new(h[:error], h[:@http_status_code], params)
      end

      def self.from_http_response(resp)
        begin
          self.deserialize(resp.body, resp)
        rescue
          Pipl::Client::APIError.new resp.message, resp.code
        end
      end

      # Here for backward compatibility
      def self.from_json(json_str)
        self.deserialize(json_str)
      end

    end

  end

end