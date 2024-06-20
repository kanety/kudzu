# frozen_string_literal: true

require 'net/http'
require 'http-cookie'
require 'addressable'
require 'nokogiri'
require 'marcel'
require 'charlock_holmes'

require 'kudzu/version'
require 'kudzu/crawler'

module Kudzu
  class << self
    attr_accessor :adapter, :agent, :logger

    def log(level, message, error: nil)
      return unless @logger
      if error
        message += " - #{error.class}: #{error.message} at #{error.backtrace.take(5).join("\n")}"
      end
      @logger.send(level, message)
    end
  end
end

Kudzu.adapter = Kudzu::Adapter::Memory
Kudzu.agent = Kudzu::Agent
