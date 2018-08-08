module Kudzu
  module Model
    module Page
      def last_modified
        last_modified = response_header['last-modified']
        Time.parse(last_modified).localtime if last_modified
      rescue
        nil
      end

      def etag
        response_header['etag']
      end

      def html?
        !mime_type.to_s.match(%r{text/html|application/xhtml\+xml}).nil?
      end

      def xml?
        !mime_type.to_s.match(%r{text/xml|application/xml|application/rss\+xml|application/atom\+xml}).nil?
      end

      def css?
        !mime_type.to_s.match(%r{text/css}).nil?
      end

      def js?
        !mime_type.to_s.match(%r{text/javascript|application/javascript|application/x-javascript}).nil?
      end

      def text?
        html? || xml? || !mime_type.to_s.match(%r{text/}).nil?
      end

      def status_success?
        200 <= status && status <= 299
      end

      def status_redirection?
        300 <= status && status <= 399
      end

      def status_client_error?
        400 <= status && status <= 499
      end

      def status_server_error?
        500 <= status && status <= 599
      end

      def status_not_modified?
        status == 304
      end

      def status_not_found?
        status == 404
      end

      def status_gone?
        status == 410
      end

      def body
        @body
      end

      def body=(body)
        @body = body
      end

      def filtered
        @filtered
      end

      def filtered=(filtered)
        @filtered = filtered
      end

      def decoded_body
        @decoded_body ||= decode_body(body)
      end

      def parsed_doc
        @parsed_doc ||= if html?
                          Nokogiri::HTML(decoded_body)
                        elsif xml?
                          Nokogiri::XML(decoded_body)
                        end
      end

      private

      def decode_body(body)
        if body && text?
          if enc = find_encoding(body)
            body.dup.force_encoding(enc).encode('utf-8', invalid: :replace, undef: :replace)
          else
            body.dup.encode('utf-8', invalid: :replace, undef: :replace)
          end
        else
          body
        end
      end

      def find_encoding(body)
        begin
          enc = Encoding.find(charset)
        rescue ArgumentError
          return nil
        end

        if enc == Encoding::Shift_JIS
          Encoding::CP932
        elsif enc == Encoding::EUC_JP
          require 'nkf'
          guessed = NKF.guess(body)
          [Encoding::EUCJP_MS, Encoding::CP51932].include?(guessed) ? guessed : enc
        else
          enc
        end
      end
    end
  end
end
