describe Kudzu::Crawler do
  let(:seed_url) { "http://localhost:9292/test/index.html" }
  let(:config_file) { Rails.root.join('config/kudzu.rb') }

  context 'run' do
    it 'single thread' do
      crawler = Kudzu::Crawler.new(thread_num: 1, log_file: STDOUT)
      crawler.run(seed_url)
      expect(crawler.repository.page.size > 0).to be_truthy
    end

    it 'multi thread' do
      crawler = Kudzu::Crawler.new(thread_num: 2, log_file: STDOUT)
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
