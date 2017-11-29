require 'nokogiri'

module Kudzu
  class Crawler
    class UrlExtractor < Kudzu::Configurable
      def initialize(config = {})
        @config = select_config(config, :url_filters, :respect_nofollow)
      end

      def extract(page)
        if page.html?
          FromHTML.new(@config).extract(page)
        elsif page.xml?
          FromXML.new(@config).extract(page)
        else
          []
        end
      end

      class FromHTML < UrlExtractor
        def initialize(config = {})
          super
          @content_type_parser = Kudzu::Util::ContentTypeParser.new
        end

        def extract(page)
          config = find_filter_config(@config[:url_filters], page.url)

          doc = Nokogiri::HTML(page.decoded_body)
          return [] if nofollow?(doc)

          if config[:allow_element]
            doc = doc.search(*Array(config[:allow_element]))
          end
          if config[:deny_element]
            doc.search(*Array(config[:deny_element])).remove
          end

          anchors = from_html(doc) + from_html_in_meta(doc)
          anchors.reject { |anchor| anchor[:url].empty? }.uniq
        end

        private

        def nofollow?(doc)
          return false unless @config[:respect_nofollow]
          nodes = doc.xpath('//meta[@name]')
          nodes.any? { |node| node[:name] =~ /^robots$/i && node[:content] =~ /nofollow/i }
        end

        def from_html(doc)
          nodes = doc.xpath('.//*[@href or @src]').to_a

          if @config[:respect_nofollow]
            nodes.reject! { |url| url[:rel] =~ /nofollow/i }
          end

          nodes.map { |node|
            Hash[url: (node[:href] || node[:src]).to_s.strip,
                 title: node_to_title(node)]
          }
        end

        def node_to_title(node)
          unless node.inner_text.empty?
            node.inner_text
          else
            (node[:title] || node[:alt]).to_s
          end
        end

        def from_html_in_meta(doc)
          nodes = doc.xpath('.//meta[@http-equiv]').select { |node| node[:'http-equiv'] =~ /^refresh$/i }
          urls = nodes.map { |node| @content_type_parser.parse(node[:content]).last[:url] }.compact
          urls.map { |url| Hash[url: url.to_s.strip] }
        end
      end

      class FromXML < UrlExtractor
        def extract(page)
          doc = Nokogiri::XML(page.decoded_body)
          doc.remove_namespaces!
          anchors = from_xml_rss(doc) + from_xml_atom(doc)
          anchors.reject { |anchor| anchor[:url].empty? }.uniq
        end

        private

        def from_xml_rss(doc)
          doc.xpath('rss/channel').map { |node|
            Hash[url: node.xpath('./item/link').inner_text.strip,
                 title: node.xpath('./item/title').inner_text]
          }
        end

        def from_xml_atom(doc)
          doc.xpath('feed/entry').map { |node|
            Hash[url: node.xpath('./link[@href]/@href').to_s.strip,
                 title: node.xpath('./title').inner_text]
          }
        end
      end
    end
  end
end
