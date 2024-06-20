# frozen_string_literal: true

module Kudzu
  class Agent
    class Util
      class Matcher
        class << self
          def match?(text, allows: nil, denies: nil)
            match_to_allows?(text, allows) && !match_to_denies?(text, denies)
          end

          private

          def match_to_allows?(text, allows)
            allows = Array(allows)
            allows.empty? || allows.any? { |allow| Kudzu::Common.match?(text, allow) }
          end

          def match_to_denies?(text, denies)
            denies = Array(denies)
            !denies.empty? && denies.any? { |deny| Kudzu::Common.match?(text, deny) }
          end
        end
      end
    end
  end
end
