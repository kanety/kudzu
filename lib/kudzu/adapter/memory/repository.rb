# frozen_string_literal: true

module Kudzu
  module Adapter
    module Memory
      class Repository
        attr_reader :page

        def initialize
          @page = {}
        end

        def find_by_url(url)
          @page[url] || Page.new(url: url)
        end

        def register(page)
          @page[page.url] = page
        end

        def delete(page)
          @page.delete(page.url)
        end
      end
    end
  end
end
