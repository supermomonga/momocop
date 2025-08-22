# frozen_string_literal: true

require 'simplecov'
require 'simplecov-console'

SimpleCov.start do
  add_filter '/spec/'
  add_filter '/vendor/'

  if ENV['CI']
    formatter SimpleCov::Formatter::SimpleFormatter
  else
    formatter SimpleCov::Formatter::MultiFormatter.new(
      [
        SimpleCov::Formatter::SimpleFormatter,
        SimpleCov::Formatter::Console
      ]
    )
  end
  minimum_coverage 100

  # enable_coverage :branch

  add_group 'Cops', 'lib/rubocop/cop'
  add_group 'Helpers', 'lib/momocop/helpers'
  add_group 'Extractors', 'lib/momocop'
  add_group 'PrismCombo', 'lib/prism_combo'
end

require 'momocop'
require 'rubocop'
require 'rubocop/rspec/support'

require_relative 'support/schema_loader'

RSpec.configure do |config|
  config.include RuboCop::RSpec::ExpectOffense

  config.raise_errors_for_deprecations!
  config.raise_on_warning = true
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = '.rspec_status'
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
