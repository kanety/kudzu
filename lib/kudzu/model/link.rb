module Kudzu
  module Model
    module Link
      def uri
        Addressable::URI.parse(url)
      end
    end
  end
end
