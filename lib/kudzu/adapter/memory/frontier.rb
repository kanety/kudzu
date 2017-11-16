module Kudzu
  module Adapter
    class Memory
      class Frontier
        def initialize(uuid, config = {})
          @uuid = uuid
          @monitor = Monitor.new
          @queue = []
          @queued = {}
        end

        def enqueue(urls, depth: 1)
          @monitor.synchronize do
            Array(urls).each do |url|
              next if @queued.key?(url)
              @queued[url] = true
              @queue << Link.new(uuid: @uuid, url: url, state: 0, depth: depth)
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
