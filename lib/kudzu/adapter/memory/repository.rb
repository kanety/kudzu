module Kudzu
  module Adapter
    module Memory
      class Repository
        attr_reader :page

        def initialize(config = {})
          config_keys = [:save_content]
          @config = config.select { |k, _| config_keys.include?(k) }
          @page = {}
          @digest = {}
        end

        def find_by_url(url)
          @page[url] || Page.new(url: url)
        end

        def register(page)
          unless @config[:save_content]
            page.body = nil
          end
          @page[page.url] = page
          @digest[page.digest] = true
        end

        def delete(page)
          @page.delete(page.url)
        end

        def exist_same_content?(page)
          !@page.key?(page.url) && @digest.key?(page.digest)
        end
      end
    end
  end
end
