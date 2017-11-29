module Kudzu
  class Logger
    def initialize(file, level)
      if file.is_a?(::Logger)
        @logger = file
      elsif file
        @logger = ::Logger.new(file)
        @logger.level = level
      else
        @logger = nil
      end
    end

    def log(level, message, error: nil)
      return unless @logger
      message += " #{error.class} #{error.message} #{error.backtrace.join("\n")}" if error
      @logger.send(level, message)
    end
  end
end
