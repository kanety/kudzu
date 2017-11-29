require_relative 'page_fetcher'

module Kudzu
  class Crawler
    class Robots
      def initialize(config = {})
        @user_agent = config[:user_agent]
        @page_fetcher = Kudzu::Crawler::PageFetcher.new(config)
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
          Parser.new.parse(body)
        else
          Parser.new.parse('')
        end
      end

      def fetch(base_uri)
        uri = base_uri.dup
        uri.path = 'robots.txt'
        uri.fragment = uri.query = nil

        begin
          @page_fetcher.fetch(uri.to_s)
        rescue
          nil
        end
      end

      class Txt
        attr_accessor :sets, :sitemaps

        def initialize
          self.sets = []
          self.sitemaps = []
        end
      end

      class RuleSet
        attr_accessor :user_agent, :rules, :crawl_delay

        def initialize(attr = {})
          self.rules = []
          attr.each { |k, v| public_send("#{k}=", v) }
        end

        def allowed_path?(uri)
          rules.each do |rule|
            return rule.allow if uri.path =~ rule.path
          end
          return true
        end
      end

      class Rule
        attr_accessor :path, :allow

        def initialize(attr = {})
          attr.each { |k, v| public_send("#{k}=", v) }
        end
      end

      class Parser
        UNMATCH_REGEXP = /^$/

        def parse(body)
          txt = Txt.new
          sets = []
          prev_key = nil

          parse_body(body).each do |key, value|
            case key
            when 'user-agent'
              new_set = RuleSet.new(user_agent: ua_regexp(value))
              txt.sets << new_set
              if prev_key == 'user-agent'
                sets << new_set
              else
                sets = [new_set]
              end
            when 'allow'
              re = path_regexp(value)
              sets.each { |set| set.rules << Rule.new(path: re, allow: true) }
            when 'disallow'
              re = path_regexp(value)
              sets.each { |set| set.rules << Rule.new(path: re, allow: false) }
            when 'crawl-delay'
              sets.each { |set| set.crawl_delay = value.to_i }
            when 'sitemap'
              txt.sitemaps << value
            end

            prev_key = key
          end

          sort(txt)
        end

        private

        def parse_body(body)
          lines = body.to_s.split(/\r|\n|\r\n/)
          lines.map { |line| parse_line(line) }.compact
        end

        def parse_line(line)
          line.strip!
          if line.empty? || line.start_with?('#')
            nil
          else
            split_line(line)
          end
        end

        def split_line(line)
          key, value = line.split(':', 2)
          key = key.to_s.strip.downcase
          value = value.to_s.sub(/#.*$/, '').strip
          if key.empty? || value.empty?
            nil
          else
            [key, value]
          end
        end

        def ua_regexp(value)
          Regexp.new(Regexp.escape(value).gsub('\*', '.*'))
        rescue RegexpError
          UNMATCH_REGEXP
        end

        def path_regexp(value)
          Regexp.new('^' + Regexp.escape(value).gsub('\*', '.*').gsub('\$', '$'))
        rescue RegexpError
          UNMATCH_REGEXP
        end

        def sort(txt)
          txt.sets.sort_by! { |rule| [-rule.user_agent.to_s.count('*'), rule.user_agent.to_s.length] }.reverse!
          txt.sets.each do |set|
            set.rules.sort_by! { |rule| rule.path.to_s.length }.reverse!
          end
          txt
        end
      end
    end
  end
end
