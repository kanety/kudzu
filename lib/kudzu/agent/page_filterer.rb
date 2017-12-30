module Kudzu
  class Agent
    class PageFilterer
      def initialize(config)
        @config = config
      end

      def allowed?(response)
        filter = @config.find_filter(response.url)

        if filter.nil? || (allowed_mime_type?(response.mime_type, filter) &&
                           allowed_size?(response.size, filter) &&
                           allowed_index?(response))
          Kudzu.log :info, "passed page: #{response.url}"
          true
        else
          Kudzu.log :info, "dropped page: #{response.url}"
          false
        end
      end

      private

      def allowed_mime_type?(mime_type, filter)
        return true if mime_type.nil?
        Util::Matcher.match?(mime_type, allows: filter.allow_mime_type, denies: filter.deny_mime_type)
      end

      def allowed_size?(size, filter)
        return true if filter.max_size.nil? || size.nil?
        size.to_i < filter.max_size.to_i
      end

      def allowed_index?(response)
        return true unless response.html?
        return true unless @config.respect_noindex

        doc = response.parsed_doc
        doc.xpath('html/head/meta[@name]')
           .all? { |meta| meta[:name] !~ /^robots$/i || meta[:content] !~ /noindex/i }
      end
    end
  end
end
