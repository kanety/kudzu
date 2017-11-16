require_relative 'page_fetcher'

module Kudzu
  class Crawler
    class Robots
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
          parse(body)
        else
          parse('')
        end
      end

      def fetch(base_uri)
        uri = base_uri.dup
        uri.path = 'robots.txt'
        uri.fragment = uri.query = nil
        @page_fetcher.fetch(uri.to_s)
      end

      def parse(robots_txt)
        txt = Txt.new
        sets = []
        prev_key = nil

        robots_txt.split(/\r|\n|\r\n/).each do |line|
          line.strip!
          next if line.empty?
          next if line.start_with?('#')

          key, value = split_line(line)
          next if key.empty? || value.empty?

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
            sets.each { |set| set.rules << Rule.new(path: re, allow: true) } if  re
          when 'disallow'
            re = path_regexp(value)
            sets.each { |set| set.rules << Rule.new(path: re, allow: false) } if re
          when 'crawl-delay'
            sets.each { |set| set.crawl_delay = value.to_i }
          when 'sitemap'
            txt.sitemaps << value
          end

          prev_key = key
        end

        sort(txt)
      end

      def split_line(line)
        key, value = line.split(':', 2)
        key = key.to_s.strip.downcase
        value = value.to_s.sub(/#.*$/, '').strip
        return key, value
      end

      def ua_regexp(value)
        Regexp.new(Regexp.escape(value).gsub('\*', '.*'))
      rescue RegexpError
        nil
      end

      def path_regexp(value)
        value = Addressable::URI.parse(value).normalize.to_s
        Regexp.new('^' + Regexp.escape(value).gsub('\*', '.*').gsub('\$', '$'))
      rescue RegexpError
        nil
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
