# frozen_string_literal: true

require 'rubocop'

# Momocop
require_relative 'momocop/association_extractor'
require_relative 'momocop/config_injector'
require_relative 'momocop/version'

Momocop::ConfigInjector.inject_default_config!

Dir[File.join(__dir__, 'rubocop/cop/momocop', '*.rb')].each do |file|
  require file
end
