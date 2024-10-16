# frozen_string_literal: true

require_relative 'config/filter'

module Kudzu
  class Config
    SIMPLE_CONFIGS   = [:config_file,
                        :user_agent, :thread_num, :open_timeout, :read_timeout, :keep_alive,
                        :max_connection, :max_redirect, :max_depth, :max_retry, :default_request_header,
                        :politeness_delay, :handle_cookie,
                        :respect_robots_txt, :respect_nofollow, :respect_noindex,
                        :filters]
    DEFAULT_CONFIG   = { user_agent: "Kudzu/#{Kudzu::VERSION}",
                         open_timeout: 10,
                         read_timeout: 10,
                         keep_alive: 5,
                         thread_num: 1,
                         max_connection: 10,
                         max_redirect: 3,
                         max_retry: 0,
                         politeness_delay: 0.5,
                         handle_cookie: true,
                         respect_robots_txt: true,
                         respect_nofollow: true,
                         respect_noindex: true }

    attr_accessor *SIMPLE_CONFIGS

    def initialize(config = {}, &block)
      self.filters = {}
      DEFAULT_CONFIG.merge(config).each do |key, value|
        send("#{key}=", value) if respond_to?("#{key}=")
      end
      if config_file || block
        delegator = Delegator.new(self)
        delegator.instance_eval(File.read(config_file)) if config_file
        delegator.instance_eval(&block) if block
      end
    end

    def add_filter(base_url = nil, config = {}, &block)
      base_uri = Addressable::URI.parse(base_url || '*')
      host = base_uri.host.presence || '*'
      path = base_uri.path.presence || '*'
      filters[host] ||= []
      filters[host] << Filter.new(path, config, &block)
    end

    def find_filter(uri)
      uri = Addressable::URI.parse(uri) if uri.is_a?(String)
      filters.each do |host, filters|
        next unless Kudzu::Common.match?(uri.host, host)
        filters.each do |filter|
          return filter if Kudzu::Common.match?(uri.path, filter.path)
        end
      end
      nil
    end

    class Delegator
      def initialize(config)
        @config = config
      end

      SIMPLE_CONFIGS.each do |key|
        define_method(key) do |value|
          @config.send("#{key}=", value)
        end
      end

      def add_filter(base_url = nil, config = {}, &block)
        @config.add_filter(base_url, config, &block)
      end
    end
  end
end
