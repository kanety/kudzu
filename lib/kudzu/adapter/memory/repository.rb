module Kudzu
  module Adapter
    module Memory
      class Repository
        attr_reader :page

        def initialize(config)
          @config = config
          @page = {}
          @digest = {}
        end

        def find_by_url(url)
          @page[url] || Page.new(url: url)
        end

        def register(page)
          unless @config.save_content
            page.body = nil
          end
          @page[page.url] = page
          @digest[page.digest] = true
        end

        def delete(page)
          @page.delete(page.url)
        end
      end
    end
  end
end
