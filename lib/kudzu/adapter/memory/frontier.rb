module Kudzu
  module Adapter
    module Memory
      class Frontier
        def initialize(uuid, config = {})
          @uuid = uuid
          @monitor = Monitor.new
          @queue = []
          @queued = {}
        end

        def enqueue(anchors, depth: 1)
          @monitor.synchronize do
            Array(anchors).each do |anchor|
              next if @queued.key?(anchor[:url])
              @queued[anchor[:url]] = true
              @queue << Link.new(uuid: @uuid,
                                 url: anchor[:url],
                                 title: anchor[:title],
                                 state: 0,
                                 depth: depth)
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
