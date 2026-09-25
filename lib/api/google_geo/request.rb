require 'net/https'
require 'uri'
require 'json'

# 最終的に https://www.geocoding.jp/api/ を使うかも

module Api
  module GoogleGeo
    class Request
      class RequestError < StandardError; end

      REDIRECT_LIMIT = 5
      OPEN_TIMEOUT = 5
      READ_TIMEOUT = 10

      attr_accessor :query

      def request(param)
        uri = URI.parse(
          'https://script.google.com/macros/s/AKfycbytzsMF7hCN7yab9fhuQCZUzOSMSGkI3Q9bXTIerROkrVCqdeS8byvTNFDLiM77o6fO/exec?' +
          URI.encode_www_form(src: param)
        )
        response = get_following_redirects(uri)
        parsed = JSON.parse(response.body)
        raise RequestError, 'geocoding API returned an unexpected payload' unless parsed.is_a?(Hash)

        parsed
      rescue RequestError
        raise
      rescue JSON::ParserError => e
        raise RequestError, "geocoding API returned invalid JSON: #{e.message}"
      rescue StandardError => e
        raise RequestError, "geocoding API request failed: #{e.message}"
      end

      private

      def get_following_redirects(uri, remaining = REDIRECT_LIMIT)
        response = http_get(uri)

        case response
        when Net::HTTPSuccess
          response
        when Net::HTTPRedirection
          raise RequestError, 'too many geocoding API redirects' if remaining <= 0

          location = response['location']
          raise RequestError, 'geocoding API redirect has no Location header' if location.nil? || location.empty?

          get_following_redirects(URI.join(uri.to_s, location), remaining - 1)
        else
          raise RequestError, "geocoding API returned HTTP #{response.code}"
        end
      end

      def http_get(uri)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == 'https'
        http.open_timeout = OPEN_TIMEOUT
        http.read_timeout = READ_TIMEOUT
        http.get(uri.request_uri)
      end
    end
  end
end
