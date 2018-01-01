module Kudzu
  class Agent
    class Response < Kudzu::Model::Base
      include Kudzu::Model::Page

      attr_accessor :url, :status, :body, :response_header, :response_time, :redirect_from, :fetched,
                    :size, :digest, :mime_type, :charset, :title

      def fetched?
        fetched
      end
    end
  end
end
