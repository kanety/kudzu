require 'ostruct'

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

      attr_accessor *SIMPLE_CONFIGS

      def initialize(config = {})
        DEFAULT_CONFIG.merge(config).each do |key, value|
          send("#{key}=", value)
        end
      end
    end

    SIMPLE_CONFIGS   = [:config_file, :user_agent, :thread_num, :open_timeout, :read_timeout,
                        :max_connection, :max_redirect, :max_depth, :default_request_header, :delay, :handle_cookie,
                        :respect_robots_txt, :respect_nofollow, :respect_noindex,
                        :save_content, :log_file, :log_level,
                        :revisit_mode, :revisit_min_interval, :revisit_max_interval, :revisit_default_interval,
                        :filters]
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
                         revisit_mode: false,
                         revisit_min_interval: 1,
                         revisit_max_interval: 10,
                         revisit_default_interval: 5,
                         filters: {} }

    attr_accessor *SIMPLE_CONFIGS

    def initialize(config = {})
      DEFAULT_CONFIG.merge(config).each do |key, value|
        send("#{key}=", value)
      end
      instance_eval(File.read(config_file)) if config_file
    end

    def add_filter(base_url = nil, config = {})
      filter = Filter.new(config)
      yield filter if block_given?

      base_uri = Addressable::URI.parse(base_url || '*')
      host = base_uri.host.presence || '*'
      filters[host] ||= []
      filters[host] << filter
    end

    def find_filters(uri)
      uri = Addressable::URI.parse(uri) if uri.is_a?(String)
      filters.inject([]) do |array, (host, filters)|
        array += filters if Kudzu::Common.match?(uri.host, host)
        array
      end
    end
  end
end
