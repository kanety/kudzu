# frozen_string_literal: true

module Kudzu
  class Common
    class << self
      def match?(text, pattern)
        if pattern.is_a?(String)
          File.fnmatch(pattern, text)
        elsif pattern.is_a?(Regexp)
          text =~ pattern
        else
          false
        end
      end

      def path_to_dir(path)
        if path.end_with?('/')
          path
        else
          dir = File.dirname(path)
          dir.end_with?('/') ? dir : dir + '/'
        end
      end
    end
  end
end
