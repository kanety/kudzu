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
        uri = Addressable::URI.parse(url)
        delay_sec = delay_second(uri)
        return unless delay_sec

        sleep_sec = sleep_second(uri, delay_sec)
        sleep sleep_sec if sleep_sec > 0
        update_last_accessed(uri)
      end

      private

      def delay_second(uri)
        if @config.respect_robots_txt && @robots && (crawl_delay = @robots.crawl_delay(uri))
          crawl_delay.to_f
        elsif @config.delay
          @config.delay.to_f
        end
      end

      def sleep_second(uri, delay_sec)
        @monitor.synchronize do
          if @last_accessed[uri.host]
            (@last_accessed[uri.host] + delay_sec) - Time.now.to_f
          else
            0
          end
        end
      end

      def update_last_accessed(uri)
        @monitor.synchronize do
          @last_accessed[uri.host] = Time.now.to_f
        end
      end
    end
  end
end
