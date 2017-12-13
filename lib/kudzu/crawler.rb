require 'addressable'
require 'nokogiri'
require_relative 'common'
require_relative 'config'
require_relative 'callback'
require_relative 'logger'
require_relative 'adapter/memory'
require_relative 'util/all'
require_relative 'agent/all'
require_relative 'revisit/all'

module Kudzu
  class Crawler
    attr_reader :uuid, :config
    attr_reader :frontier, :repository

    def initialize(options = {}, &block)
      @uuid = options[:uuid] || SecureRandom.uuid
      @config = Kudzu::Config.new(options, &block)
    end

    def prepare(&block)
      @logger = Kudzu::Logger.new(@config.log_file, @config.log_level)
      @callback = Kudzu::Callback.new(&block)

      @frontier = Kudzu.adapter::Frontier.new(@uuid)
      @repository = Kudzu.adapter::Repository.new(@config)

      @robots = Kudzu::Agent::Robots.new(@config)
      @page_fetcher = Kudzu::Agent::Fetcher.new(@config, @robots)
      @page_filter = Kudzu::Agent::Filter.new(@config)
      @charset_detector = Kudzu::Agent::CharsetDetector.new
      @mime_type_detector = Kudzu::Agent::MimeTypeDetector.new
      @title_parser = Kudzu::Agent::TitleParser.new

      @url_extractor = Kudzu::Agent::UrlExtractor.new(@config)
      @url_filter = Kudzu::Agent::UrlFilter.new(@config)

      @revisit_scheduler = Kudzu::Revisit::Scheduler.new(@config)
    end

    def run(seed_url, &block)
      prepare(&block)

      seeds = Array(seed_url).map { |url| { url: url } }
      enqueue_hrefs(seeds, 1)

      if @config.thread_num.to_i <= 1
        single_thread
      else
        multi_thread(@config.thread_num)
      end

      @page_fetcher.pool.close
      @frontier.clear
    end

    private

    def single_thread
      loop do
        link = @frontier.dequeue.first
        break unless link
        visit_link(link)
      end
    end

    def multi_thread(thread_num)
      @thread_pool = Kudzu::Util::ThreadPool.new(thread_num)

      @thread_pool.start do |queue|
        limit_num = [thread_num - queue.size, 0].max
        @frontier.dequeue(limit: limit_num).each do |link|
          queue.push(link)
        end
        link = queue.pop
        visit_link(link)
      end

      @thread_pool.wait
      @thread_pool.shutdown
    end

    def visit_link(link)
      page = @repository.find_by_url(link.url)
      response = fetch_link(link, build_request_header(page))
      return unless response

      page = @repository.find_by_url(response.url) if response.redirected?
      page.url = response.url
      page.status = response.status
      page.response_time = response.time
      page.fetched_at = Time.now

      if page.status_success?
        handle_success(page, link, response)
      elsif page.status_not_modified?
        @revisit_scheduler.schedule(page, modified: false)
        register_page(page)
      elsif page.status_not_found? || page.status_gone?
        delete_page(page)
      end

      run_callback(page, link)
    end

    def run_callback(page, link)
      if page.status_success?
        if page.filtered
          @callback.on(:filter, page, link)
        else
          @callback.on(:success, page, link)
        end
      elsif page.status_redirection?
        @callback.on(:redirection, page, link)
      elsif page.status_client_error?
        @callback.on(:client_error, page, link)
      elsif page.status_server_error?
        @callback.on(:server_error, page, link)
      end
    end

    def build_request_header(page)
      header = @config.default_request_header.to_h
      if @config.revisit_mode
        header['If-Modified-Since'] = page.last_modified.httpdate if page.last_modified
        header['If-None-Match'] = page.etag if page.etag
      end
      header
    end

    def fetch_link(link, request_header)
      response = @page_fetcher.fetch(link.url, request_header: request_header)
      @logger.log :info, "page fetched: #{response.status} #{response.url}"
      response
    rescue Exception => e
      @logger.log :warn, "couldn't fetch page: #{link.url}", error: e
      @callback.on(:failure, link, e)
      nil
    end

    def handle_success(page, link, response)
      digest = Digest::MD5.hexdigest(response.body)
      @revisit_scheduler.schedule(page, modified: page.digest != digest)

      page.response_header = response.header
      page.body = response.body
      page.size = response.body.size
      page.mime_type = detect_mime_type(page)
      page.charset = detect_charset(page)
      page.title = parse_title(page)
      page.redirect_from = link.url if response.redirected?
      page.revised_at = Time.now if page.digest != digest
      page.digest = digest

      if follow_hrefs_from?(page, link)
        hrefs = extract_hrefs(page, page.url)
        enqueue_hrefs(hrefs, link.depth + 1) unless hrefs.empty?
      end

      if allowed_page?(page)
        register_page(page)
      else
        page.filtered = true
        delete_page(page)
      end
    end

    def detect_mime_type(page)
      @mime_type_detector.detect(page)
    rescue => e
      @logger.log :warn, "couldn't detect mime type for #{page.url}", error: e
      nil
    end

    def detect_charset(page)
      if page.text?
        @charset_detector.detect(page)
      else
        nil
      end
    rescue => e
      @logger.log :warn, "couldn't detect charset for #{page.url}", error: e
      nil
    end

    def parse_title(page)
      if page.html?
        @title_parser.parse(page)
      else
        Addressable::URI.parse(page.url).basename
      end
    rescue => e
      @logger.log :warn, "couldn't parse title for #{page.url}", error: e
      nil
    end

    def follow_hrefs_from?(page, link)
      (page.html? || page.xml?) && (@config.max_depth.nil? || link.depth < @config.max_depth.to_i)
    end

    def extract_hrefs(page, base_url)
      hrefs = @url_extractor.extract(page, base_url)
      passed, dropped = @url_filter.filter(hrefs, base_url)

      if @config.respect_robots_txt
        passed, dropped_by_robots = passed.partition { |href| @robots.allowed?(href[:url]) }
        dropped += dropped_by_robots
      end

      if @config.log_level == :debug
        passed.each { |href| @logger.log :debug, "url passed: #{href[:url]}" }
        dropped.each { |href| @logger.log :debug, "url dropped: #{href[:url]}" }
      end

      passed
    rescue => e
      @logger.log :warn, "couldn't extract links from #{page.url}", error: e
      []
    end

    def allowed_page?(page)
      if @page_filter.allowed?(page) &&
         !@repository.exist_same_content?(page) &&
         (!page.redirect_from || @url_filter.allowed?(page.url, page.redirect_from)) 
        @logger.log :info, "page passed: #{page.url}"
        true
      else
        @logger.log :info, "page dropped: #{page.url}"
        false
      end
    end

    def register_page(page)
      @callback.around(:register, page) do
        @repository.register(page)
      end
    end

    def delete_page(page)
      @callback.around(:delete, page) do
        @repository.delete(page)
      end
    end

    def enqueue_hrefs(hrefs, depth)
      links = hrefs.map do |href|
                Kudzu.adapter::Link.new(uuid: @uuid,
                                       url: href[:url],
                                       title: href[:title],
                                       state: 0,
                                       depth: depth)
              end
      @callback.around(:enqueue, links) do
        @frontier.enqueue(links, depth: depth)
      end
    end
  end
end
