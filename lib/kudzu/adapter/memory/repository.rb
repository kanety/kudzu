module Kudzu
  module Adapter
    module Memory
      class Repository
        attr_reader :page

        def initialize
          @page = {}
          @digest = {}
        end

        def find_by_url(url)
          @page[url] || Page.new(url: url)
        end

        def register(page)
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
