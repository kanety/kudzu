# frozen_string_literal: true

module Kudzu
  class Agent
    class UrlFilterer
      def initialize(config, robots = nil)
        @config = config
        @robots = robots
      end

      def filter(refs, base_url)
        base_uri = Addressable::URI.parse(base_url)
        filter = @config.find_filter(base_uri)

        refs.select do |ref|
          if allowed?(ref.uri, base_uri, filter: filter)
            Kudzu.log :debug, "passed url: #{ref.url}"
            true
          else
            Kudzu.log :debug, "dropped url: #{ref.url}"
            false
          end
        end
      end

      def allowed?(uri, base_uri, filter: nil)
        uri = Addressable::URI.parse(uri) if uri.is_a?(String)
        base_uri = Addressable::URI.parse(base_uri) if base_uri.is_a?(String)
        filter ||= @config.find_filter(base_uri)
        return true unless filter

        focused_host?(uri, base_uri, filter) &&
          focused_descendants?(uri, base_uri, filter) &&
          allowed_url?(uri, filter) &&
          allowed_host?(uri, filter) &&
          allowed_path?(uri, filter) &&
          allowed_ext?(uri, filter) &&
          allowed_by_robots?(uri)
      end

      private

      def focused_host?(uri, base_uri, filter)
        return true unless filter.focus_host
        uri.host == base_uri.host
      end

      def focused_descendants?(uri, base_uri, filter)
        return true unless filter.focus_descendants
        dir = Kudzu::Common.path_to_dir(uri.path)
        base_dir = Kudzu::Common.path_to_dir(base_uri.path)
        uri.host == base_uri.host && dir =~ /^#{Regexp.escape(base_dir)}/i
      end

      def allowed_url?(uri, filter)
        Util::Matcher.match?(uri.to_s, allows: filter.allow_url, denies: filter.deny_url)
      end

      def allowed_host?(uri, filter)
        Util::Matcher.match?(uri.host, allows: filter.allow_host, denies: filter.deny_host)
      end

      def allowed_path?(uri, filter)
        Util::Matcher.match?(uri.path, allows: filter.allow_path, denies: filter.deny_path)
      end

      def allowed_ext?(uri, filter)
        ext = uri.extname.to_s.sub(/^\./, '')
        return true if ext.empty?
        Util::Matcher.match?(ext, allows: filter.allow_ext, denies: filter.deny_ext)
      end

      def allowed_by_robots?(uri)
        return true unless @robots
        return true unless @config.respect_robots_txt
        @robots.allowed?(uri)
      end
    end
  end
end
