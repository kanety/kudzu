module Kudzu
  module Adapter
    module Memory
      class Page < Kudzu::Model::Base
        include Kudzu::Model::Page

        attr_accessor :url, :title, :status, :mime_type, :size, :charset, :digest,
                      :response_header, :response_time, :redirect_from, :fetched_at, :revised_at
      end
    end
  end
end
