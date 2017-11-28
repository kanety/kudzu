$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "kudzu/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "kudzu"
  s.version     = Kudzu::VERSION
  s.authors     = ["Yoshikazu Kaneta"]
  s.email       = ["kaneta@sitebridge.co.jp"]
  s.homepage    = "https://github.com/kanety/kudzu"
  s.summary     = "A simple web crawler for ruby"
  s.description = "A simple web crawler for ruby"
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "addressable"
  s.add_dependency "nokogiri"
  s.add_dependency "charlock_holmes"
  s.add_dependency "shared-mime-info"
  s.add_dependency "mime-types"

  s.add_development_dependency "rails"
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "simplecov"
  s.add_development_dependency "pry-rails"
  s.add_development_dependency "pry-byebug"
end
