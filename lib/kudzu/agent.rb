# frozen_string_literal: true

require_relative 'agent/all'

module Kudzu
  class Agent
    def initialize(config, &block)
      @config = config

      @robots = Robots.new(@config)
      @fetcher = Fetcher.new(@config, @robots)
      @url_extractor = UrlExtractor.new(@config)
      @url_filterer = UrlFilterer.new(@config, @robots)
      @page_filterer = PageFilterer.new(@config)
    end

    def start
      yield
      @fetcher.pool.close
   end

    def fetch(url, request_header = {})
      response = @fetcher.fetch(url, request_header: request_header)
      return response unless response.fetched?

      response.size = response.body.size
      response.digest = Digest::MD5.hexdigest(response.body)
      response.mime_type = Util::MimeTypeDetector.detect(response)
      response.charset = Util::CharsetDetector.detect(response) if response.text?
      response.title = Util::TitleParser.parse(response)
      response
    end

    def extract_refs(response)
      return [] unless redirect_url_allowed?(response)
      refs = @url_extractor.extract(response)
      @url_filterer.filter(refs, response.url)
    end

    def filter_response?(response)
      return true unless redirect_url_allowed?(response)
      !@page_filterer.allowed?(response)
    end

    private

    def redirect_url_allowed?(response)
      return true if response.redirect_from.nil? || response.redirect_from.empty?
      @url_filterer.allowed?(response.url, response.redirect_from)
    end
  end
end
