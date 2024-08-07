# frozen_string_literal: true

require 'parser/current'
require 'rubocop'

# rubocop-rails
require 'rubocop/cop/mixin/active_record_helper'
require 'rubocop/rails/schema_loader'
require 'rubocop/rails/schema_loader/schema'

# sevencop
require 'sevencop/cop_concerns'

# Momocop
require_relative 'momocop/association_extractor'
require_relative 'momocop/config_injector'
require_relative 'momocop/enum_extractor'
require_relative 'momocop/version'

Dir[File.join(__dir__, 'momocop/helpers', '*.rb')].each do |file|
  require file
end

Momocop::ConfigInjector.inject_default_config!

Dir[File.join(__dir__, 'rubocop/cop/momocop', '**', '*.rb')].each do |file|
  require file
end
