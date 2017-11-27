module Kudzu
  class Configurable
    def select_config(config, *keys)
      config.select { |k, _| keys.include?(k) }
    end

    def find_filter_config(filters, base_uri)
      Array(filters).each do |host, path_filters|
        if Kudzu::Common.match?(base_uri.host, host)
          path_filters.each do |path, filter|
            if Kudzu::Common.match?(base_uri.path, path)
              return filter.config
            end
          end
        end
      end
      return {}
    end
  end
end
