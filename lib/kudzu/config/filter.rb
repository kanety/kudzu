# frozen_string_literal: true

module Kudzu
  class Config
    class Filter
      SIMPLE_CONFIGS = [# url filter
                        :focus_host, :focus_descendants, :allow_element, :deny_element,
                        :allow_url, :deny_url, :allow_host, :deny_host, :allow_path, :deny_path,
                        :allow_ext, :deny_ext,
                        # page filter
                        :allow_mime_type, :deny_mime_type, :max_size]
      DEFAULT_CONFIG = { focus_host: false,
                         focus_descendants: false }

      attr_accessor :path
      attr_accessor *SIMPLE_CONFIGS

      def initialize(path, config = {}, &block)
        @path = path
        DEFAULT_CONFIG.merge(config).each do |key, value|
          send("#{key}=", value)
        end
        if block
          Delegator.new(self).instance_eval(&block)
        end
      end

      class Delegator
        def initialize(filter)
          @filter = filter
        end

        SIMPLE_CONFIGS.each do |key|
          define_method(key) do |value|
            @filter.send("#{key}=", value)
          end
        end
      end
    end
  end
end
