require 'nokogiri'

module Kudzu
  class Crawler
    class TitleParser
      def parse(page)
        doc = Nokogiri::HTML(page.decoded_body)
        if (node = doc.xpath('//head/title').first)
          node.inner_text.to_s
        else
          ''
        end
      end
    end
  end
end
