module Kudzu
  class Url
    class Filter
      def initialize(config)
        @config = config
        @matcher = Kudzu::Util::Matcher.new
      end

      def filter(hrefs, base_url)
        base_uri = Addressable::URI.parse(base_url)
        filters = @config.find_filters(base_uri)

        hrefs.partition do |href|
          allowed?(href[:url], base_uri, filters: filters)
        end
      end

      def allowed?(url, base_uri, filters: nil)
        uri = Addressable::URI.parse(url)
        base_uri = Addressable::URI.parse(base_uri) if base_uri.is_a?(String)
        filters ||= @config.find_filters(base_uri)

        filters.all? do |filter|
          focused_host?(uri, base_uri, filter) &&
            focused_descendants?(uri, base_uri, filter) &&
            allowed_url?(uri, filter) &&
            allowed_host?(uri, filter) &&
            allowed_path?(uri, filter) &&
            allowed_ext?(uri, filter)
        end
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
        @matcher.match?(uri.to_s, allows: filter.allow_url, denies: filter.deny_url)
      end

      def allowed_host?(uri, filter)
        @matcher.match?(uri.host, allows: filter.allow_host, denies: filter.deny_host)
      end

      def allowed_path?(uri, filter)
        @matcher.match?(uri.path, allows: filter.allow_path, denies: filter.deny_path)
      end

      def allowed_ext?(uri, filter)
        ext = uri.extname.to_s.sub(/^\./, '')
        return true if ext.empty?
        @matcher.match?(ext, allows: filter.allow_ext, denies: filter.deny_ext)
      end
    end
  end
end
