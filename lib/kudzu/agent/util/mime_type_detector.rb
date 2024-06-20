# frozen_string_literal: true

module Kudzu
  class Agent
    class Util
      class MimeTypeDetector
        DEFALUT_MIME_TYPE = 'application/octet-stream'

        class << self
          def detect(response)
            from_header(response.response_header) ||
              from_body(response.body) ||
              from_url(response.url) ||
              DEFALUT_MIME_TYPE
          rescue => e
            Kudzu.log :warn, "failed to detect mime: #{response.url}", error: e
            nil
          end

          private

          def from_header(header)
            ContentTypeParser.parse(header['content-type']).first
          end

          def from_body(body)
            mime = Marcel::Magic.by_magic(StringIO.new(body))
            mime.to_s if mime
          end

          def from_url(url)
            uri = Addressable::URI.parse(url)
            mime = Marcel::Magic.by_path(uri.basename)
            mime.to_s if mime
          end
        end
      end
    end
  end
end
