require 'kudzu/util/matcher'

module Kudzu
  class Crawler
    class UrlFilter < Kudzu::Configurable
      def initialize(config = {}, robots = nil)
        @config = select_config(config, :user_agent, :respect_robots_txt, :url_filters)
        @robots = robots
        @matcher = Kudzu::Util::Matcher.new
      end

      def filter(urls, base_url)
        config = filter_config(base_url)

        urls.partition do |url|
          allowed?(url, base_url, config: config)
        end
      end

      def allowed?(url, base_url, config: nil)
        uri = Addressable::URI.parse(url)
        base_uri = Addressable::URI.parse(base_url)
        config ||= filter_config(base_url)

        focused_host?(uri, base_uri, config) &&
          focused_descendants?(uri, base_uri, config) &&
          allowed_url?(uri, config) &&
          allowed_host?(uri, config) &&
          allowed_path?(uri, config) &&
          allowed_ext?(uri, config) &&
          allowed_by_robots?(uri, config)
      end

      private

      def filter_config(base_url)
        find_filter_config(@config[:url_filters], base_url)
      end

      def focused_host?(uri, base_uri, config)
        return true unless config[:focus_host]
        uri.host == base_uri.host
      end

      def focused_descendants?(uri, base_uri, config)
        return true unless config[:focus_descendants]
        dir = Kudzu::Common.path_to_dir(uri.path)
        base_dir = Kudzu::Common.path_to_dir(base_uri.path)
        uri.host == base_uri.host && dir =~ /^#{Regexp.escape(base_dir)}/i
      end

      def allowed_url?(uri, config)
        @matcher.match?(uri.to_s, allows: config[:allow_url], denies: config[:deny_url])
      end

      def allowed_host?(uri, config)
        @matcher.match?(uri.host, allows: config[:allow_host], denies: config[:deny_host])
      end

      def allowed_path?(uri, config)
        @matcher.match?(uri.path, allows: config[:allow_path], denies: config[:deny_path])
      end

      def allowed_ext?(uri, config)
        ext = uri.extname.to_s.sub(/^\./, '')
        return true if ext.empty?
        @matcher.match?(ext, allows: config[:allow_ext], denies: config[:deny_ext])
      end

      def allowed_by_robots?(uri, config)
        return true if !@config[:respect_robots_txt] || @robots.nil?
        @robots.allowed?(uri)
      end
    end
  end
end
