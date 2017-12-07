require 'nokogiri'

module Kudzu
  class Agent
    class Filter
      def initialize(config)
        @config = config
        @matcher = Kudzu::Util::Matcher.new
      end

      def allowed?(page)
        filter = @config.find_filter(page.url)
        return true unless filter

        allowed_mime_type?(page.mime_type, filter) && allowed_size?(page.size, filter) && allowed_index?(page)
      end

      private

      def allowed_mime_type?(mime_type, filter)
        return true if mime_type.nil?
        @matcher.match?(mime_type, allows: filter.allow_mime_type, denies: filter.deny_mime_type)
      end

      def allowed_size?(size, filter)
        return true if filter.max_size.nil? || size.nil?
        size.to_i < filter.max_size.to_i
      end

      def allowed_index?(page)
        return true unless page.html?
        return true unless @config.respect_noindex

        doc = Nokogiri::HTML(page.body.encode('ascii', undef: :replace, invalid: :replace))
        doc.xpath('html/head/meta[@name]')
           .all? { |meta| meta[:name] !~ /^robots$/i || meta[:content] !~ /noindex/i }
      end
    end
  end
end
