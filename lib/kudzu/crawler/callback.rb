module Kudzu
  class Crawler
    class Callback < Kudzu::Configurable
      CALLBACKS = [:on_success,      # 2xx
                   :on_redirection,  # 3xx
                   :on_client_error, # 4xx
                   :on_server_error, # 5xx
                   :on_filter,       # 2xx, filtered
                   :on_failure,      # Exception
                   :before_register,
                   :after_register,
                   :before_delete,
                   :after_delete,
                   :before_enqueue, 
                   :after_enqueue,
                   ]

      def initialize
        @callback = {}
      end

      CALLBACKS.each do |key|
        define_method(key) do |&block|
          @callback[key] = block
        end
      end

      def on(name, *args)
        on_name = "on_#{name}".to_sym
        @callback[on_name].call(*args) if @callback.key?(on_name)
      end

      def around(name, *args)
        before_name = "before_#{name}".to_sym
        after_name = "after_#{name}".to_sym
        @callback[before_name].call(*args) if @callback.key?(before_name)
        yield
        @callback[after_name].call(*args) if @callback.key?(after_name)
      end
    end
  end
end
