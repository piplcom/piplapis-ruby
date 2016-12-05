require 'date'
require 'uri'

module Pipl

  module Utils

    class << self

      def str_to_date(s)
        Date.strptime(s, DATE_FORMAT)
      end

      def date_to_str(d)
        d.strftime(DATE_FORMAT)
      end

      def is_valid_url?(url)
        not ((url =~ URI::ABS_URI).nil?)
      end

      def alpha_chars(s)
        s.gsub(/[^\p{Alpha}]/, '')
      end

      def alnum_chars(s)
        s.gsub(/[^\p{Alnum}]/, '')
      end

      def titleize(s)
        s.gsub(/\w+/) { |x| x.capitalize }
      end

      def to_utf8(obj)
        if obj.respond_to?(:encode)
          begin
            obj.encode('UTF-8')
          rescue Exception
            puts "Could not convert #{obj} to UTF-8"
            raise
          end
        else
          obj
        end
      end

      def extract_rate_limits(headers={})
        res = {}
        res[:qps_allotted] = headers['X-QPS-Allotted'].to_i if headers.key? 'X-QPS-Allotted'
        res[:qps_current] = headers['X-QPS-Current'].to_i if headers.key? 'X-QPS-Current'
        res[:qps_live_allotted] = headers['X-QPS-Live-Allotted'].to_i if headers.key? 'X-QPS-Live-Allotted'
        res[:qps_live_current] = headers['X-QPS-Live-Current'].to_i if headers.key? 'X-QPS-Live-Current'
        res[:qps_demo_allotted] = headers['X-QPS-Demo-Allotted'].to_i if headers.key? 'X-QPS-Demo-Allotted'
        res[:qps_demo_current] = headers['X-QPS-Demo-Current'].to_i if headers.key? 'X-QPS-Demo-Current'
        res[:quota_allotted] = headers['X-APIKey-Quota-Allotted'].to_i if headers.key? 'X-APIKey-Quota-Allotted'
        res[:quota_current] = headers['X-APIKey-Quota-Current'].to_i if headers.key? 'X-APIKey-Quota-Current'
        res[:quota_reset] = DateTime.strptime(headers['X-Quota-Reset'], '%A, %B %d, %Y %I:%M:%S %p %Z') if headers.key? 'X-Quota-Reset'
        res[:demo_usage_allotted] = headers['X-Demo-Usage-Allotted'].to_i if headers.key? 'X-Demo-Usage-Allotted'
        res[:demo_usage_current] = headers['X-Demo-Usage-Current'].to_i if headers.key? 'X-Demo-Usage-Current'
        res[:demo_usage_expiry] = DateTime.strptime(headers['X-Demo-Usage-Expiry'], '%A, %B %d, %Y %I:%M:%S %p %Z') if headers.key? 'X-Demo-Usage-Expiry'
        res
      end

    end

  end

end
