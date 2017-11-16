module Kudzu
  module Adapter
    class Memory
      class Page
        include Kudzu::Adapter::Base::Page

        attr_accessor :url, :status, :mime_type, :size, :charset, :digest,
                      :response_header, :response_time, :fetched_at,
                      :revisit_interval, :revisit_at

        def initialize(attr = {})
          attr.each { |k, v| public_send("#{k}=", v) if respond_to?("#{k}=") }
        end
      end
    end
  end
end
