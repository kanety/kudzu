module Kudzu
  class Agent
    class Sleeper
      def initialize(config, robots = nil)
        @config = config
        @robots = robots
        @monitor = Monitor.new
        @last_accessed = {}
      end

      def delay(url)
        delay_sec = delay_second(url)
        return unless delay_sec

        sleep_sec = sleep_second(url, delay_sec)
        sleep sleep_sec if sleep_sec > 0
      end

      private

      def delay_second(url)
        if @config.respect_robots_txt && @robots && @robots.crawl_delay(url)
          @robots.crawl_delay(url).to_f
        elsif @config.delay
          @config.delay.to_f
        end
      end

      def sleep_second(url, delay_sec)
        uri = Addressable::URI.parse(url)
        @monitor.synchronize do
          value = if @last_accessed[uri.host]
                    (@last_accessed[uri.host] + delay_sec) - Time.now.to_f
                  else
                    0
                  end
          @last_accessed[uri.host] = Time.now.to_f
          value
        end
      end
    end
  end
end
