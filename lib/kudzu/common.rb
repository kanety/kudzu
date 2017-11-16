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
          File.dirname(path) + '/'
        end
      end
    end
  end
end
