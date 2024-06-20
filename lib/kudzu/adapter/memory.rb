# frozen_string_literal: true

Dir[File.join(__dir__, 'memory/**/*.rb')].each do |file|
  require_relative file
end
