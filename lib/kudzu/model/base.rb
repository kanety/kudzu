# frozen_string_literal: true

module Kudzu
  module Model
    class Base
      def initialize(attr = {})
        attr.each { |k, v| public_send("#{k}=", v) if respond_to?("#{k}=") }
      end
    end
  end
end
