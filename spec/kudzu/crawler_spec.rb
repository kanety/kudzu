describe Kudzu::Crawler do
  let(:seed_url) { "http://localhost:9292/test/index.html" }
  let(:config_file) { Rails.root.join('config/kudzu.rb') }

  context 'run' do
    it 'single thread' do
      crawler = Kudzu::Crawler.new(thread_num: 1, log_file: STDERR, log_level: :debug)
      crawler.run(seed_url) do
        on_success do |page, link|
          puts "on_success: #{page.status} #{page.url}"
        end
        on_redirection do |page, link|
          puts "on_redirection: #{page.status} #{page.url}"
        end
        on_client_error do |page, link|
          puts "on_client error: #{page.status} #{page.url}"
        end
        on_server_error do |page, link|
          puts "on_server error: #{page.status} #{page.url}"
        end
        on_failure do |link, e|
          puts "on_failure: #{link.url} #{e}"
        end
        before_register do |page|
          puts "before_register: #{page.url}"
        end
        after_register do |page|
          puts "after_register: #{page.url}"
        end
        before_delete do |page|
          puts "before_delete: #{page.url}"
        end
        after_delete do |page|
          puts "after_delete: #{page.url}"
        end
        before_enqueue do |links|
          puts "before_enqueue: #{links.size}"
        end
        after_enqueue do |links|
          puts "after_enqueue: #{links.size}"
        end
      end
      expect(crawler.repository.page.size > 0).to be_truthy
    end

    it 'multi thread' do
      crawler = Kudzu::Crawler.new(thread_num: 2)
      crawler.run(seed_url)
      expect(crawler.repository.page.size > 0).to be_truthy
    end

    it 'with configs' do
      crawler = Kudzu::Crawler.new(config_file: config_file)
      crawler.run(seed_url)
      expect(crawler.repository.page.size > 0).to be_truthy
    end
  end
end
