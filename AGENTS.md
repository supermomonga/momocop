# Momocop Development Guide

## Build/Lint/Test Commands
- Run all tests: `bundle exec rspec` or `bin/rspec`
- Run single test: `bundle exec rspec spec/path/to/spec.rb:line_number`
- Run linter: `bundle exec rubocop` or `bin/rubocop`
- Run all checks: `bundle exec rake` (runs both specs and rubocop)
- Auto-fix linting: `bundle exec rubocop -a`

## Code Style Guidelines
- Ruby version: 3.1.1+
- Always use `frozen_string_literal: true` comment at the top of Ruby files
- Line length: max 120 characters
- Use semantic block delimiters (do...end for multi-line, {} for single-line)
- Inline access modifiers preferred (e.g., `private def method_name`)
- Follow RuboCop configuration in `.rubocop.yml`
- Test files use RSpec with `--format documentation`
- Cop classes inherit from `RuboCop::Cop::Base`
- Use node pattern matchers for AST analysis
- Include appropriate helper modules (FactoryBotHelper, RailsHelper)

## Project Structure
- Custom cops: `lib/rubocop/cop/momocop/`
- Specs mirror cop structure: `spec/rubocop/cop/momocop/`
- Use `RuboCop::RSpec::ExpectOffense` for testing cops