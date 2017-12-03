describe Kudzu::Crawler do
  let(:seed_url) { "http://localhost:9292/test/index.html" }
  let(:config_file) { Rails.root.join('config/kudzu.rb') }

  context 'run' do
    it 'single thread' do
      crawler = Kudzu::Crawler.new(thread_num: 1, log_file: STDERR, log_level: :debug)
      crawler.run(seed_url) do |c|
        c.on_success do |page, link|
          puts "on_success: #{page.status} #{page.url}"
        end
        c.on_redirection do |page, link|
          puts "on_redirection: #{page.status} #{page.url}"
        end
        c.on_client_error do |page, link|
          puts "on_client error: #{page.status} #{page.url}"
        end
        c.on_server_error do |page, link|
          puts "on_server error: #{page.status} #{page.url}"
        end
        c.on_failure do |link, e|
          puts "on_failure: #{link.url} #{e}"
        end
        c.before_register do |page|
          puts "before_register: #{page.url}"
        end
        c.after_register do |page|
          puts "after_register: #{page.url}"
        end
        c.before_delete do |page|
          puts "before_delete: #{page.url}"
        end
        c.after_delete do |page|
          puts "after_delete: #{page.url}"
        end
        c.before_enqueue do |links|
          puts "before_enqueue: #{links.size}"
        end
        c.after_enqueue do |links|
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
