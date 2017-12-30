module Kudzu
  class Agent
    class Response < Kudzu::Model::Base
      include Kudzu::Model::Page

      attr_accessor :url, :status, :body, :response_header, :response_time, :redirect_from,
                    :size, :digest, :mime_type, :charset, :title
    end
  end
end
