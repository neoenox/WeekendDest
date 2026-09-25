require 'net/https'
require 'uri'
require 'json'

module Api
  module GoogleRoute
    class Request
      class RequestError < StandardError; end

      REDIRECT_LIMIT = 5
      OPEN_TIMEOUT = 5
      READ_TIMEOUT = 10

      attr_accessor :query

      def request(route)
        uri = URI.parse('https://script.google.com/macros/s/AKfycbyPvT1K338SNJT_NdqZrqYCw-UxMXOKboW6wM3X8aTIw1bFwNi0Ks8K1jpikrVRfgKC/exec')
        response = post(uri, { routes: route }.to_json)
        response = follow_redirects(response, uri)

        parsed = JSON.parse(response.body)
        raise RequestError, 'route API returned an unexpected payload' unless parsed.is_a?(Hash)

        parsed
      rescue RequestError
        raise
      rescue JSON::ParserError => e
        raise RequestError, "route API returned invalid JSON: #{e.message}"
      rescue StandardError => e
        raise RequestError, "route API request failed: #{e.message}"
      end

      private

      def post(uri, body)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == 'https'
        http.open_timeout = OPEN_TIMEOUT
        http.read_timeout = READ_TIMEOUT
        http.post(uri.request_uri, body, 'Content-Type' => 'application/json')
      end

      def follow_redirects(response, uri, remaining = REDIRECT_LIMIT)
        case response
        when Net::HTTPSuccess
          response
        when Net::HTTPRedirection
          raise RequestError, 'too many route API redirects' if remaining <= 0

          location = response['location']
          raise RequestError, 'route API redirect has no Location header' if location.nil? || location.empty?

          next_uri = URI.join(uri.to_s, location)
          follow_redirects(get(next_uri), next_uri, remaining - 1)
        else
          raise RequestError, "route API returned HTTP #{response.code}"
        end
      end

      def get(uri)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == 'https'
        http.open_timeout = OPEN_TIMEOUT
        http.read_timeout = READ_TIMEOUT
        http.get(uri.request_uri)
      end
    end
  end
end
