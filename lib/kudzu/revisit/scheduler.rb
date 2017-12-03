module Kudzu
  class Revisit
    class Scheduler
      def initialize(config)
        @config = config
      end

      def schedule(page, modified: true)
        page.revisit_interval = next_interval(page.revisit_interval, modified)
        page.revisit_at = page.fetched_at + page.revisit_interval * 86400
      end

      private

      def next_interval(curr_interval, modified)
        if curr_interval
          if modified
            [curr_interval - 1, @config.revisit_min_interval].max
          else
            [curr_interval + 1, @config.revisit_max_interval].min
          end
        else
          @config.revisit_default_interval
        end
      end
    end
  end
end
