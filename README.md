# Kudzu

A simple web crawler for ruby.

## Features

* Single-thread mode and multi-thread mode.
* HTTP connection pooling.
* Adaptable web page store.
* Restrict outgoing links by url-based patterns.
* Detect charset for text pages.
* Respect robots.txt.
* Schedule re-visit interval using modification frequency.

## Dependencies

* ruby 2.3+

## Page store

This gem supports only in-memory crawling by default. Use following adapter to store pages persistently:

* [kudzu_active_record](https://github.com/kanety/kudzu_active_record)

## Installation

Add to your application's Gemfile:

```ruby
gem 'kudzu'
```

Then run:

    $ bundle install

## Usage

Crawl html files in `example.com`:

```ruby
crawler = Kudzu::Crawler.new {
  user_agent 'YOUR_AWESOME_APP'
  url_filter {
    focus_host true
  }
  page_filter {
    allow_mime_type %w(text/html)
  }
}
crawler.run('http://example.com/')
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/kanety/kudzu. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
