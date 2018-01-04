module Kudzu
  class Agent
    class Reference < Kudzu::Model::Base
      include Kudzu::Model::Link

      attr_accessor :url, :title
    end
  end
end
