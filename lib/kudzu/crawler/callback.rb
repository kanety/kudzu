module Kudzu
  class Crawler
    class Callback < Kudzu::Configurable
      CALLBACKS = [:on_success,      # 2xx
                   :on_redirection,  # 3xx
                   :on_client_error, # 4xx
                   :on_server_error, # 5xx
                   :on_filter,       # 2xx, filtered
                   :on_failure,      # Exception
                   ]

      def initialize
        @callback = {}
      end

      CALLBACKS.each do |key|
        define_method(key) do |&block|
          @callback[key] = block
        end
      end

      def run(name, *args)
        @callback[name].call(*args) if @callback.key?(name)
      end
    end
  end
end
