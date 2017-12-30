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
      message += " #{error.class} #{error.message} #{error.backtrace.join("\n")}" if error
      @logger.send(level, message)
    end
  end
end

Kudzu.adapter = Kudzu::Adapter::Memory
Kudzu.agent = Kudzu::Agent
