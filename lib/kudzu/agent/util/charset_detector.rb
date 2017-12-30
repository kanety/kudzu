module Kudzu
  class Agent
    class Util
      class CharsetDetector
        CORRECTION = {
          'utf_8' => 'utf-8',
          'shift-jis' => 'shift_jis',
          'x-sjis' => 'shift_jis',
          'euc_jp' => 'euc-jp'
        }

        class << self
          def detect(response)
            if response.html?
              from_html(response.body) || from_text(response.body)
            elsif response.xml?
              from_xml(response.body) || from_text(response.body)
            elsif response.text?
              from_text(response.body)
            end
          rescue => e
            Kudzu.log :warn, "failed to detect charset: #{response.url}", error: e
            nil
          end

          private

          def from_html(body)
            doc = Nokogiri::HTML(body.encode('utf-8', undef: :replace, invalid: :replace))

            if (node = doc.xpath('//meta/@charset').first)
              charset = correct(node.to_s)
              return charset if charset
            end

            doc.xpath('//meta[@http-equiv]').each do |meta|
              if meta['http-equiv'] =~ /content-type/i
                charset = ContentTypeParser.parse(meta[:content].to_s)[1][:charset]
                charset = correct(node.to_s)
                return charset if charset
              end
            end

            return nil
          end

          def from_xml(body)
            doc = Nokogiri::XML(body.encode('utf-8', undef: :replace, invalid: :replace))
            if doc.encoding
              correct(doc.encoding)
            else
              nil
            end
          end

          def from_text(text)
            if text.ascii_only?
              'ascii'
            else
              detection = CharlockHolmes::EncodingDetector.detect(text)
              if detection && detection.key?(:encoding)
                detection[:encoding].downcase
              else
                nil
              end
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
  end
end
