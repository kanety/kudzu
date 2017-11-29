module Kudzu
  class Crawler
    class DSL
      SIMPLE_CONFIGS   = [:user_agent, :thread_num, :open_timeout, :read_timeout,
                          :max_connection, :max_redirect, :max_depth, :default_request_header, :delay, :handle_cookie,
                          :respect_robots_txt, :respect_nofollow, :respect_noindex,
                          :save_content, :log_file, :log_level,
                          :revisit_mode, :revisit_min_interval, :revisit_max_interval, :revisit_default_interval,
                          :url_filters, :page_filters]
      DEFAULT_CONFIG   = { user_agent: "Kudzu/#{Kudzu::VERSION}",
                           open_timeout: 10,
                           read_timeout: 10,
                           thread_num: 1,
                           max_connection: 10,
                           max_redirect: 3,
                           delay: 0.5,
                           handle_cookie: true,
                           respect_robots_txt: true,
                           respect_nofollow: true,
                           respect_noindex: true,
                           save_content: true,
                           log_level: :debug,
                           revisit_mode: false,
                           revisit_min_interval: 1,
                           revisit_max_interval: 10,
                           revisit_default_interval: 5,
                           url_filters: {},
                           page_filters: {} }

      attr_reader :config

      def initialize(config = {})
        @config = DEFAULT_CONFIG.merge(config)
      end

      SIMPLE_CONFIGS.each do |key|
        define_method(key) do |value|
          @config[key] = value
        end
      end

      def url_filter(base_url = nil, config = {}, &block)
        filter = UrlFilter.new(config)
        filter.instance_eval(&block) if block

        base_uri = Addressable::URI.parse(base_url || '*')
        host = base_uri.host.presence || '*'
        path = base_uri.path.presence || '*'
        @config[:url_filters][host] ||= {}
        @config[:url_filters][host][path] = filter
      end

      class UrlFilter
        SIMPLE_CONFIGS = [:focus_host, :focus_descendants, :allow_element, :deny_element,
                          :allow_url, :deny_url, :allow_host, :deny_host, :allow_path, :deny_path,
                          :allow_ext, :deny_ext]
        DEFAULT_CONFIG = { focus_host: false,
                           focus_descendants: false }

        attr_reader :config

        def initialize(config = {})
          @config = DEFAULT_CONFIG.merge(config)
        end

        SIMPLE_CONFIGS.each do |key|
          define_method(key) do |value|
            @config[key] = value
          end
        end
      end

      def page_filter(base_url = nil, config = {}, &block)
        filter = PageFilter.new(config)
        filter.instance_eval(&block) if block

        base_uri = Addressable::URI.parse(base_url || '*')
        host = base_uri.host.presence || '*'
        path = base_uri.path.presence || '*'
        @config[:page_filters][host] ||= {}
        @config[:page_filters][host][path] = filter
      end

      class PageFilter
        SIMPLE_CONFIGS = [:allow_mime_type, :deny_mime_type, :max_size]

        attr_reader :config

        def initialize(config = {})
          @config = config
        end

        SIMPLE_CONFIGS.each do |key|
          define_method(key) do |value|
            @config[key] = value
          end
        end
      end
    end
  end
end
