require_relative 'boot'

require 'action_controller/railtie'

Bundler.require(*Rails.groups)
require "kudzu"

module Dummy
  class Application < Rails::Application
    config.load_defaults Rails::VERSION::STRING.to_f
  end
end

