require_relative 'model/all'
require_relative 'adapter/memory'
require_relative 'agent'
require_relative 'callback'
require_relative 'common'
require_relative 'config'
require_relative 'thread_pool'

module Kudzu
  class Crawler
    attr_reader :uuid, :config
    attr_reader :frontier, :repository, :agent

    def initialize(options = {}, &block)
      @uuid = options[:uuid] || SecureRandom.uuid
      @config = Kudzu::Config.new(options, &block)

      @frontier = Kudzu.adapter::Frontier.new(@uuid)
      @repository = Kudzu.adapter::Repository.new
      @agent = Kudzu.agent.new(@config)
    end

    def run(seed_url, &block)
      @callback = Kudzu::Callback.new(&block)

      seed_refs = Array(seed_url).map { |url| Kudzu::Agent::Reference.new(url: url) }
      enqueue_links(refs_to_links(seed_refs, 1))

      @agent.start do
        if @config.thread_num.to_i <= 1
          single_thread
        else
          multi_thread(@config.thread_num)
        end
      end

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
      @thread_pool = Kudzu::ThreadPool.new(thread_num)

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
      response = fetch(link, @config.default_request_header.to_h)
      return unless response

      page = @repository.find_by_url(response.url)
      page.url = response.url
      page.status = response.status
      page.response_time = response.response_time
      page.fetched_at = Time.now

      if response.fetched?
        if page.status_success?
          handle_success(page, link, response)
        elsif page.status_not_modified?
          register_page(page)
        elsif page.status_not_found? || page.status_gone?
          delete_page(page)
        end
      else
        page.filtered = true
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

    def fetch(link, request_header)
      response = nil
      @callback.around(:fetch, link, request_header, response) do
        response = @agent.fetch(link.url, request_header)
      end
      if response.fetched?
        Kudzu.log :info, "fetched page: #{response.status} #{response.url}"
      else
        Kudzu.log :info, "skipped page: #{response.status} #{response.url}"
      end
      response
    rescue Exception => e
      Kudzu.log :warn, "failed to fetch page: #{link.url}", error: e
      @callback.on(:failure, link, e)
      nil
    end

    def handle_success(page, link, response)
      page.response_header = response.response_header
      page.body = response.body
      page.size = response.size
      page.mime_type = response.mime_type
      page.charset = response.charset
      page.title = response.title
      page.redirect_from = response.redirect_from
      page.revised_at = Time.now if page.digest != response.digest
      page.digest = response.digest

      if @config.max_depth.nil? || link.depth < @config.max_depth.to_i
        refs = @agent.extract_refs(response)
        enqueue_links(refs_to_links(refs, link.depth + 1)) unless refs.empty?
      end

      if @agent.filter_response?(response)
        page.filtered = true
        delete_page(page)
      else
        register_page(page)
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

    def refs_to_links(refs, depth)
      refs.map do |ref|
        Kudzu.adapter::Link.new(uuid: @uuid,
                                url: ref.url,
                                title: ref.title,
                                state: 0,
                                depth: depth)
      end
    end

    def enqueue_links(links)
      @callback.around(:enqueue, links) do
        @frontier.enqueue(links)
      end
    end
  end
end
