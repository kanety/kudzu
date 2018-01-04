module Kudzu
  class Agent
    class Util
      class TitleParser
        class << self
          def parse(response)
            if response.html?
              from_html(response.parsed_doc)
            else
              Addressable::URI.parse(response.url).basename
            end
          rescue => e
            Kudzu.log :warn, "failed to parse title: #{response.url}", error: e
            nil
          end

          private

          def from_html(doc)
            if (node = doc.xpath('//head/title').first)
              node.inner_text.to_s
            else
              ''
            end
          end
        end
      end
    end
  end
end
