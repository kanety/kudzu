module Kudzu
  module Model
    module Link
      def uri
        Addressable::URI.parse(url)
      end

      def status_success?
        200 <= status && status <= 299
      end

      def status_redirection?
        300 <= status && status <= 399
      end
    end
  end
end
