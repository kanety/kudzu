# frozen_string_literal: true

module Kudzu
  class Agent
    class Robots
      class Txt < Kudzu::Model::Base
        attr_accessor :sets, :sitemaps

        def initialize
          self.sets = []
          self.sitemaps = []
        end
      end

      class RuleSet < Kudzu::Model::Base
        attr_accessor :user_agent, :rules, :crawl_delay

        def initialize(attr = {})
          self.rules = []
          super
        end

        def allowed_path?(uri)
          rules.each do |rule|
            return rule.allow if uri.path =~ rule.path
          end
          return true
        end
      end

      class Rule < Kudzu::Model::Base
        attr_accessor :path, :allow
      end
    end
  end
end
