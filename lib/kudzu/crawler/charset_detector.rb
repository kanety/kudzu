require 'nokogiri'
require 'charlock_holmes'

module Kudzu
  class Crawler
    class CharsetDetector
      CORRECTION = {
        'utf_8' => 'utf-8',
        'shift-jis' => 'shift_jis',
        'x-sjis' => 'shift_jis',
        'euc_jp' => 'euc-jp'
      }

      def initialize
        @parser = Kudzu::Util::ContentTypeParser.new
      end

      def detect(page)
        if page.html?
          from_html(page.body) || from_text(page.body)
        elsif page.xml?
          from_xml(page.body) || from_text(page.body)
        elsif page.text?
          from_text(page.body)
        end
      end

      private

      def from_html(body)
        doc = Nokogiri::HTML(body.encode('ascii', undef: :replace, invalid: :replace))

        if (node = doc.xpath('//meta/@charset').first)
          charset = correct(node.to_s)
          return charset if charset
        end

        doc.xpath('//meta[@http-equiv]').each do |meta|
          if meta['http-equiv'] =~ /content-type/i
            charset = @parser.parse(meta[:content].to_s)[1][:charset]
            charset = correct(node.to_s)
            return charset if charset
          end
        end

        return nil
      end

      def from_xml(body)
        doc = Nokogiri::XML(body.encode('ascii', undef: :replace, invalid: :replace))
        if doc.encoding
          correct(doc.encoding)
        else
          nil
        end
      end

      def from_text(text)
        if text.ascii_only?
          'ascii'
        elsif (detection = CharlockHolmes::EncodingDetector.detect(text))
          detection[:encoding].downcase
        else
          'utf-8'
        end
      end

      def correct(charset)
        charset = charset.downcase
        charset = CORRECTION[charset] if CORRECTION.key?(charset)

        begin
          Encoding.find(charset)
        rescue
          charset = nil
        end
        charset
      end
    end
  end
end
