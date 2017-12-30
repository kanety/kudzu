module Kudzu
  class Agent
    class UrlExtractor
      def initialize(config)
        @config = config
      end

      def extract(response)
        refs = if response.html?
                 ForHTML.new(@config).extract(response)
               elsif response.xml?
                 ForXML.new(@config).extract(response)
               else
                 []
               end

        refs.each do |ref|
          ref.url = sanitize(ref.url)
          ref.url = normalize(ref.url, response.url)
        end
        refs.reject { |ref| ref.url.nil? }.uniq
      end

      private

      def sanitize(url)
        url.gsub(/^( |　|%20)+/, '')
      end

      def normalize(url, base_url)
        uri = Addressable::URI.parse(base_url).join(url).normalize
        uri.path = '/' unless uri.path
        uri.path = uri.path.gsub(%r|/{2,}|, '/')
        uri.fragment = nil

        if uri.scheme.in?(%w(http https))
          uri.to_s
        else
          nil
        end
      rescue => e
        Kudzu.log :warn, "failed to normalize url: #{url}", error: e
        nil
      end

      class ForHTML
        def initialize(config)
          @config = config
        end

        def extract(response)
          doc = response.parsed_doc
          return [] if @config.respect_nofollow && nofollow?(doc)

          if (filter = @config.find_filter(response.url))
            if filter.allow_element
              doc = doc.search(*Array(filter.allow_element))
            end
            if filter.deny_element
              doc = doc.dup
              doc.search(*Array(filter.deny_element)).remove
            end
          end

          refs = from_html(doc) + from_meta(doc)
          refs.reject { |ref| ref.url.nil? || ref.url.empty? }
        end

        private

        def nofollow?(doc)
          nodes = doc.xpath('//meta[@name]')
          nodes.any? { |node| node[:name] =~ /^robots$/i && node[:content] =~ /nofollow/i }
        end

        def from_html(doc)
          nodes = doc.xpath('.//*[@href or @src]').to_a

          if @config.respect_nofollow
            nodes.reject! { |url| url[:rel] =~ /nofollow/i }
          end

          nodes.map do |node|
            Reference.new(url: (node[:href] || node[:src]).to_s,
                          title: node_to_title(node))
          end
        end

        def node_to_title(node)
          unless node.inner_text.empty?
            node.inner_text
          else
            (node[:title] || node[:alt]).to_s
          end
        end

        def from_meta(doc)
          nodes = doc.xpath('.//meta[@http-equiv]').select { |node| node[:'http-equiv'] =~ /^refresh$/i }
          urls = nodes.map { |node| Util::ContentTypeParser.parse(node[:content]).last[:url] }.compact
          urls.map do |url|
            Reference.new(url: url.to_s)
          end
        end
      end

      class ForXML
        def initialize(config)
          @config = config
        end

        def extract(response)
          doc = response.parsed_doc.dup
          doc.remove_namespaces!

          refs = from_rss(doc) + from_atom(doc)
          refs.reject { |ref| ref.url.nil? || ref.url.empty? }
        end

        private

        def from_rss(doc)
          doc.xpath('rss/channel').map do |node|
            Reference.new(url: node.xpath('./item/link').inner_text,
                          title: node.xpath('./item/title').inner_text)
          end
        end

        def from_atom(doc)
          doc.xpath('feed/entry').map do |node|
            Reference.new(url: node.xpath('./link[@href]/@href').to_s,
                          title: node.xpath('./title').inner_text)
          end
        end
      end
    end
  end
end
