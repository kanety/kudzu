require_relative 'agent/all'

module Kudzu
  class Agent
    attr_reader :response

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
      @response = nil
    end

    def fetch(url, request_header = {})
      @response = nil
      @response = @fetcher.fetch(url, request_header: request_header)

      @response.size = @response.body.size
      @response.digest = Digest::MD5.hexdigest(@response.body)
      @response.mime_type = Util::MimeTypeDetector.detect(@response)
      @response.charset = Util::CharsetDetector.detect(@response) if @response.text?
      @response.title = Util::TitleParser.parse(@response)
      @response
    end

    def extract_refs
      refs = @url_extractor.extract(@response)
      @url_filterer.filter(refs, @response.url)
    end

    def filter_page?
      return false if @response.redirect_from && !@url_filterer.allowed?(@response.url, @response.redirect_from)
      !@page_filterer.allowed?(@response)
    end
  end
end
