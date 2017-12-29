module Kudzu
  module Adapter
    module Memory
      class Page
        include Kudzu::Adapter::Base::Page

        attr_accessor :url, :title, :status, :mime_type, :size, :charset, :digest,
                      :response_header, :response_time, :redirect_from, :fetched_at, :revised_at

        def initialize(attr = {})
          attr.each { |k, v| public_send("#{k}=", v) if respond_to?("#{k}=") }
        end
      end
    end
  end
end
