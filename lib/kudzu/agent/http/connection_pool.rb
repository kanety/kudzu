module Kudzu
  class Agent
    class Http
      class ConnectionPool
        def initialize(max_size = 10)
          @max_size = max_size
        end

        def checkout(name)
          pool[name] ||= Connection.new(name: name, http: yield)

          conn = pool[name]
          conn.last_used = Time.now

          if pool.size > @max_size
            reduce
          end

          conn.http
        end

        def close
          pool.values.each do |conn|
            finish_http(conn.http)
          end
          Thread.current[:kudzu_connection] = nil
        end

        private

        def pool
          Thread.current[:kudzu_connection] ||= {}
          Thread.current[:kudzu_connection]
        end

        def reduce
          conns = pool.values.sort_by { |conn| conn.last_used }
          conns.first(pool.size - @max_size).each do |conn|
            finish_http(conn.http)
            pool.delete(conn.name)
          end
        end

        def finish_http(http)
          http.finish if http && http.started?
        end
      end
    end
  end
end
