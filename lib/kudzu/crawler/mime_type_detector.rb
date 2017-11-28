require 'shared-mime-info'

module Kudzu
  class Crawler
    class MimeTypeDetector
      DEFALUT_MIME_TYPE = 'application/octet-stream'

      def initialize
        @content_type_parser = Kudzu::Util::ContentTypeParser.new
      end

      def detect(page)
        from_header(page.response_header) || from_body(page.body) || from_url(page.url) || DEFALUT_MIME_TYPE
      end

      private

      def from_header(header)
        @content_type_parser.parse(header['content-type']).first
      end

      def from_body(body)
        mime = MIME.check_magics(StringIO.new(body))
        mime.to_s if mime
      end

      def from_url(url)
        uri = Addressable::URI.parse(url)
        mime = MIME.check_globs(uri.basename)
        mime.to_s if mime
      end
    end
  end
end
