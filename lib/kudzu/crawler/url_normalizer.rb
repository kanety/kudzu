module Kudzu
  class Crawler
    class UrlNormalizer
      def normalize(url, base_url)
        uri = Addressable::URI.parse(base_url.to_s).join(url.to_s).normalize
        uri.path = '/' unless uri.path
        uri.fragment = nil

        if uri.scheme.in?(%w(http https))
          uri.to_s
        else
          nil
        end
      end
    end
  end
end
