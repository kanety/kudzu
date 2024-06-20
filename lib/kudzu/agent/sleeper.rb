# frozen_string_literal: true

module Kudzu
  class Agent
    class Sleeper
      def initialize(config, robots = nil)
        @config = config
        @robots = robots
        @monitor = Monitor.new
        @last_accessed = {}
      end

      def politeness_delay(uri)
        uri = Addressable::URI.parse(uri) if uri.is_a?(String)
        delay_sec = delay_second(uri)
        return unless delay_sec

        sleep_sec = sleep_second(uri, delay_sec)
        sleep sleep_sec if sleep_sec > 0
      end

      private

      def delay_second(uri)
        if @config.respect_robots_txt && @robots && (crawl_delay = @robots.crawl_delay(uri))
          crawl_delay.to_f
        elsif @config.politeness_delay
          @config.politeness_delay.to_f
        end
      end

      def sleep_second(uri, delay_sec)
        @monitor.synchronize do
          now = Time.now.to_f
          value = if @last_accessed[uri.host]
                    (@last_accessed[uri.host] + delay_sec) - now
                  else
                    0
                  end
          @last_accessed[uri.host] = now + value
          value
        end
      end
    end
  end
end
