module Kudzu
  module Adapter
    module Memory
      class Link
        include Kudzu::Adapter::Base::Link

        attr_accessor :uuid, :url, :state, :depth

        def initialize(attr = {})
          attr.each { |k, v| public_send("#{k}=", v) if respond_to?("#{k}=") }
        end
      end
    end
  end
end
