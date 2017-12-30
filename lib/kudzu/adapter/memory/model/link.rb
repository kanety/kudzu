module Kudzu
  module Adapter
    module Memory
      class Link < Kudzu::Model::Base
        include Kudzu::Model::Link

        attr_accessor :uuid, :url, :title, :state, :depth
      end
    end
  end
end
