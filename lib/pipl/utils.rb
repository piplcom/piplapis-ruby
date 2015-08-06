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

    end

  end

end
