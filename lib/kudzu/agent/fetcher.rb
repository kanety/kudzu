module Kudzu
  class Agent
    class Fetcher
      attr_reader :pool

      def initialize(config, robots = nil)
        @config = config
        @pool = Http::ConnectionPool.new(@config.max_connection || 100)
        @sleeper = Sleeper.new(@config, robots)
        @jar = HTTP::CookieJar.new
      end

      def fetch(url, request_header: {}, method: :get, redirect: @config.max_redirect, redirect_from: nil)
        uri = Addressable::URI.parse(url)
        request = build_request(uri, request_header: request_header, method: method)
        response, response_time = send_request(uri, request)

        if redirection?(response.code) && response['location'] && redirect > 0
          fetch(uri.join(response['location']).to_s, request_header: request_header,
                                                     redirect: redirect - 1,
                                                     redirect_from: redirect_from || url)
        else
          build_response(url, response, response_time, redirect_from)
        end
      end

      private

      def pool_name(uri)
        "#{uri.scheme}_#{uri.host}_#{uri.port || uri.default_port}"
      end

      def send_request(uri, request)
        start_http(uri, request) do |http|
          http.request(request)
        end
      end

      def start_http(uri, request)
        http = @pool.checkout(pool_name(uri)) { build_http(uri) }
        append_cookie(uri, request) if @config.handle_cookie

        @sleeper.politeness_delay(uri)
        start = Time.now.to_f
        response = yield http
        response_time = Time.now.to_f - start

        parse_cookie(uri, response) if @config.handle_cookie

        return response, response_time
      end

      def build_http(uri)
        http = Net::HTTP.new(uri.host, uri.port || uri.default_port)
        http.open_timeout = @config.open_timeout if @config.open_timeout
        http.read_timeout = @config.read_timeout if @config.read_timeout
        http.keep_alive_timeout = @config.keep_alive if @config.keep_alive
        if uri.scheme == 'https'
          http.use_ssl = true
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end
        http.start
      end

      def build_request(uri, request_header:, method:)
        request = Object.const_get("Net::HTTP::#{method.capitalize}").new(uri.request_uri)
        request.basic_auth uri.user, uri.password if uri.user && uri.password

        request['User-Agent'] = @config.user_agent
        request_header.each do |key, value|
          request[key] = value
        end
        request
      end

      def build_response(url, response, response_time, redirect_from)
        Response.new(url: url,
                     status: response.code.to_i,
                     body: response.body.to_s,
                     response_header: Hash[response.each.to_a],
                     response_time: response_time,
                     redirect_from: redirect_from)
      end

      def redirection?(code)
        code = code.to_i
        300 <= code && code <= 399
      end

      def parse_cookie(uri, response)
        @jar.parse(response['set-cookie'], uri.to_s) if response['set-cookie']
      end

      def append_cookie(uri, request)
        cookies = @jar.cookies(uri.to_s)
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
