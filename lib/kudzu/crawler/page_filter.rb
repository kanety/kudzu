require 'nokogiri'
require 'kudzu/util/matcher'

module Kudzu
  class Crawler
    class PageFilter < Kudzu::Configurable
      def initialize(config = {})
        @config = select_config(config, :page_filters, :respect_noindex)
        @matcher = Kudzu::Util::Matcher.new
      end

      def allowed?(page)
        config = find_filter_config(@config[:page_filters], page.url)

        allowed_mime_type?(page.mime_type, config) &&
          allowed_size?(page.size, config) &&
          allowed_index?(page, config)
      end

      private

      def allowed_mime_type?(mime_type, config)
        return true if mime_type.nil?
        @matcher.match?(mime_type, allows: config[:allow_mime_type], denies: config[:deny_mime_type])
      end

      def allowed_size?(size, config)
        return true if config[:max_size].nil? || size.nil?
        size.to_i < config[:max_size].to_i
      end

      def allowed_index?(page, config)
        return true unless page.html?
        return true unless @config[:respect_noindex]

        doc = Nokogiri::HTML(page.body.encode('ascii', undef: :replace, invalid: :replace))
        doc.xpath('html/head/meta[@name]')
           .all? { |meta| meta[:name] !~ /^robots$/i || meta[:content] !~ /noindex/i }
      end
    end
  end
end
