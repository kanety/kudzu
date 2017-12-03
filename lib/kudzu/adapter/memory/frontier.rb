module Kudzu
  module Adapter
    module Memory
      class Frontier
        def initialize(uuid)
          @uuid = uuid
          @monitor = Monitor.new
          @queue = []
          @queued = {}
        end

        def enqueue(links, depth: 1)
          @monitor.synchronize do
            Array(links).each do |link|
              next if @queued.key?(link.url)
              @queued[link.url] = true
              @queue << link
            end
          end
        end

        def dequeue(limit: 1)
          @monitor.synchronize do
            links = @queue.shift(limit)
            links.each do |link|
              link.state = 1
            end
          end
        end

        def clear
          @queue.clear
          @queued.clear
        end
      end
    end
  end
end
