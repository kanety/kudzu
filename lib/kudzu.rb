require 'net/http'
require 'http-cookie'
require 'addressable'
require 'nokogiri'
require 'shared-mime-info'
require 'charlock_holmes'

require 'kudzu/version'
require 'kudzu/crawler'

module Kudzu
  class << self
    attr_accessor :adapter, :agent, :logger

    def log(level, message, error: nil)
      return unless @logger
      if error
        message += " #{error.class} #{error.message}"
        message += " #{error.backtrace.join("\n")}" if level == :error || level == :fatal
      end
      @logger.send(level, message)
    end
  end
end

Kudzu.adapter = Kudzu::Adapter::Memory
Kudzu.agent = Kudzu::Agent
