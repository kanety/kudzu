module Kudzu
  class << self
    attr_accessor :adapter
  end
end

require 'kudzu/version'
require 'kudzu/crawler'
