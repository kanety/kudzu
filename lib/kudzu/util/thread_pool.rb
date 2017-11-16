module Kudzu
  class Util
    class ThreadPool
      def initialize(size)
        @size = size
        @queue = Queue.new
        @threads = []
      end

      def start(&block)
        @threads = 1.upto(@size).map { create_thread(&block) }
      end

      def wait
        until @queue.num_waiting == @threads.select { |t| t.alive? }.size
          Thread.pass
          sleep 1
        end
      end

      def shutdown
        @threads.each { |t| t.kill }
        @threads = []
      end

      private

      def create_thread(&block)
        Thread.start do
          loop do
            ret = block.call(@queue)
            break if ret == :end
          end
        end
      end
    end
  end
end
