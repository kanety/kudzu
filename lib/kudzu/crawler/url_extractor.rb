require 'nokogiri'

module Kudzu
  class Crawler
    class UrlExtractor < Kudzu::Configurable
      def initialize(config = {})
        @config = select_config(config, :url_filters, :respect_nofollow)
        @content_type_parser = Kudzu::Util::ContentTypeParser.new
      end

      def extract(page)
        uri = Addressable::URI.parse(page.url)
        config = find_filter_config(@config[:url_filters], uri)

        if page.html?
          extract_from_html(page.body, config)
        elsif page.xml?
          extract_from_xml(page.body, config)
        else
          []
        end
      end

      private

      def extract_from_html(body, config = {})
        doc = Nokogiri::HTML(body.encode('utf-8', undef: :replace, invalid: :replace))

        if @config[:respect_nofollow]
          if doc.xpath('//meta[@name]')
                .any? { |meta| meta[:name] =~ /^robots$/i && meta[:content] =~ /nofollow/i }
            return []
          end
        end

        if config[:allow_element]
          doc = doc.search(*Array(config[:allow_element]))
        end
        if config[:deny_element]
          doc.search(*Array(config[:deny_element])).remove
        end

        urls = from_html_base(doc) + from_html_meta(doc)
        urls.uniq
      end

      def from_html_base(doc)
        urls = doc.xpath('.//*[@href or @src]').to_a

        if @config[:respect_nofollow]
          urls.reject! { |url| url[:rel] =~ /nofollow/i }
        end

        urls.map { |node| node[:href] || node[:src] }.compact
      end

      def from_html_meta(doc)
        metas = doc.xpath('.//meta[@http-equiv]')
        metas.select { |meta| meta[:'http-equiv'] =~ /^refresh$/i }
             .map { |meta| @content_type_parser.parse(meta[:content]).last[:url] }.compact
      end

      def extract_from_xml(body, config = {})
        doc = Nokogiri::XML(body.encode('utf-8', undef: :replace, invalid: :replace))
        urls = from_xml_rss(doc) + from_xml_atom(doc)
        urls.uniq
      end

      def from_xml_rss(doc)
        doc.xpath('rss/channel/item/link').map { |node| node.inner_text }
      end

      def from_xml_atom(doc)
        doc.xpath('feed/entry/link[@href]').map { |node| node[:href] }
      end
    end
  end
end
