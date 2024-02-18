# frozen_string_literal: true

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
