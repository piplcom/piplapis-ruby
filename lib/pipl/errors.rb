module Pipl

  class AbstractMethodInvoked < StandardError;
  end

  class Client

    class APIError < Exception
      attr_reader :status_code
      attr_reader :qps_allotted, :qps_current, :qps_live_allotted, :qps_live_current, :qps_demo_allotted,
                  :qps_demo_current, :quota_allotted, :quota_current, :quota_reset, :demo_usage_allotted,
                  :demo_usage_current, :demo_usage_expiry

      def initialize(message, status_code, params={})
        super message
        @status_code = status_code
        @qps_allotted = params[:qps_allotted]
        @qps_current = params[:qps_current]
        @qps_live_allotted = params[:qps_live_allotted]
        @qps_live_current = params[:qps_live_current]
        @qps_demo_allotted = params[:qps_demo_allotted]
        @qps_demo_current = params[:qps_demo_current]
        @quota_allotted = params[:quota_allotted]
        @quota_current = params[:quota_current]
        @quota_reset = params[:quota_reset]
        @demo_usage_allotted = params[:demo_usage_allotted]
        @demo_usage_current = params[:demo_usage_current]
        @demo_usage_expiry = params[:demo_usage_expiry]
      end

      def is_user_error?
        (400..499).member?(@status_code)
      end

      def is_pipl_error?
        not is_user_error?
      end

      def self.deserialize(json_str, headers={})
        h = JSON.parse(json_str, symbolize_names: true)
        params = Utils::extract_rate_limits(headers)
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