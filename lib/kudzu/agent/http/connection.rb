module Kudzu
  class Agent
    class Http
      class Connection < Kudzu::Model::Base
        attr_accessor :name, :http, :last_used
      end
    end
  end
end
