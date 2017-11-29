describe Kudzu::Crawler do
  let(:seed_url) { "http://localhost:9292/test/index.html" }
  let(:config_file) { Rails.root.join('config/kudzu.rb') }

  context 'run' do
    it 'single thread' do
      crawler = Kudzu::Crawler.new(thread_num: 1, log_file: STDOUT, log_level: :debug)
      crawler.run(seed_url) do |c|
        c.on_success do |page, link|
          puts "success: #{page.status} #{page.url}"
        end
        c.on_redirection do |page, link|
          puts "redirection: #{page.status} #{page.url}"
        end
        c.on_client_error do |page, link|
          puts "client error: #{page.status} #{page.url}"
        end
        c.on_server_error do |page, link|
          puts "server error: #{page.status} #{page.url}"
        end
        c.on_failure do |link, e|
          puts "failure: #{link.url} #{e}"
        end
      end
      expect(crawler.repository.page.size > 0).to be_truthy
    end

    it 'multi thread' do
      crawler = Kudzu::Crawler.new(thread_num: 2, log_file: STDOUT, log_level: :debug)
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
