module Kudzu
  class Agent
    class Robots
      def initialize(config)
        @user_agent = config.user_agent
        @fetcher = Fetcher.new(config)
        @monitor = Monitor.new
        @txt = {}
      end

      def allowed?(uri)
        uri = Addressable::URI.parse(uri) if uri.is_a?(String)
        set = find_set(uri)
        return true unless set
        set.allowed_path?(uri)
      end

      def crawl_delay(uri)
        uri = Addressable::URI.parse(uri) if uri.is_a?(String)
        set = find_set(uri)
        return nil unless set
        set.crawl_delay
      end

      def sitemaps(uri)
        uri = Addressable::URI.parse(uri) if uri.is_a?(String)
        txt = find_txt(uri)
        return [] unless txt
        txt.sitemaps
      end

      private

      def find_txt(uri)
        @monitor.synchronize do
          @txt[uri.host] ||= fetch_and_parse(uri)
        end
      end

      def find_set(uri)
        txt = find_txt(uri)
        return unless txt

        txt.sets.each do |set|
          return set if @user_agent =~ set.user_agent
        end
        return nil
      end

      def fetch_and_parse(uri)
        response = fetch(uri)
        if response && response.status == 200
          body = response.body.force_encoding('utf-8').encode('utf-8', undef: :replace, invalid: :replace)
          Parser.parse(body)
        else
          Parser.parse('')
        end
      end

      def fetch(base_uri)
        uri = base_uri.dup
        uri.path = 'robots.txt'
        uri.fragment = uri.query = nil

        begin
          @fetcher.fetch(uri.to_s)
        rescue => e
          Kudzu.log :error, "failed to fetch robots.txt: #{uri}", error: e
          nil
        end
      end
    end
  end
end
