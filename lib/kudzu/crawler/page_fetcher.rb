require 'net/http'
require 'http-cookie'
require 'kudzu/util/connection_pool'
require 'kudzu/crawler/sleeper'

module Kudzu
  class Crawler
    class PageFetcher < Kudzu::Configurable
      class Response
        attr_accessor :url, :status, :header, :body, :time, :redirected
  
        def initialize(attr = {})
          attr.each { |k, v| public_send("#{k}=", v) }
        end

        def redirected?
          redirected
        end
      end

      attr_reader :pool

      def initialize(config = {}, robots = nil)
        @config = select_config(config, :user_agent, :open_timeout, :read_timeout, :max_redirect, :handle_cookie)
        @pool = Util::ConnectionPool.new(config[:max_connection] || 100)
        @sleeper = Kudzu::Crawler::Sleeper.new(config, robots)
        @jar = HTTP::CookieJar.new
      end

      def fetch(url, request_header: {}, redirect: max_redirect)
        uri = Addressable::URI.parse(url)
        http = @pool.checkout(pool_name(uri)) { build_http(uri) }
        request = build_request(uri, request_header)

        append_cookie(url, request) if @config[:handle_cookie]

        @sleeper.delay(url)

        response = nil
        response_time = Benchmark.realtime { response = http.request(request) }

        parse_cookie(url, response) if @config[:handle_cookie]

        if redirection?(response.code) && response['location'] && redirect > 0
          fetch(uri.join(response['location']).to_s, request_header: request_header, redirect: redirect - 1)
        else
          res = build_response(url, response, response_time)
          res.redirected = (redirect != max_redirect)
          res
        end
      end

      private

      def max_redirect
        @config[:max_redirect] || 5
      end

      def pool_name(uri)
        "#{uri.scheme}_#{uri.host}_#{uri.port || uri.default_port}"
      end

      def build_http(uri)
        http = Net::HTTP.new(uri.host, uri.port || uri.default_port)
        http.open_timeout = @config[:open_timeout] if @config[:open_timeout]
        http.read_timeout = @config[:read_timeout] if @config[:read_timeout]
        if uri.scheme == 'https'
          http.use_ssl = true
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end
        http.start
      end

      def build_request(uri, request_header)
        request = Net::HTTP::Get.new(uri.request_uri)
        request.basic_auth uri.user, uri.password if uri.user && uri.password

        request['User-Agent'] = @config[:user_agent]
        request_header.each do |key, value|
          request[key] = value
        end
        request
      end

      def build_response(url, response, response_time)
        Response.new(url: url,
                     status: response.code.to_i,
                     header: Hash[response.each.to_a],
                     body: response.body.to_s,
                     time: response_time)
      end

      def redirection?(code)
        code = code.to_i
        300 <= code && code <= 399
      end

      def parse_cookie(url, response)
        @jar.parse(response['set-cookie'], url) if response['set-cookie']
      end

      def append_cookie(url, request)
        cookies = @jar.cookies(url)
        unless cookies.empty?
          if request['Cookie']
            request['Cookie'] += '; ' + cookies.join('; ')
          else
            request['Cookie'] = cookies.join('; ')
          end
        end
      end
    end
  end
end
