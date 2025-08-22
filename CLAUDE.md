# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Momocop is a RuboCop extension gem that provides highly opinionated custom cops for enforcing code conventions. It focuses on FactoryBot, RSpec, and Rails-specific linting rules.

## Essential Commands

### Testing
```bash
# Run all specs to ensure all tests are passed.
bin/rspec --format progress

# Run a specific spec file
bin/rspec spec/rubocop/cop/momocop/[cop_name]_spec.rb --format progress

# Run specs with coverage
bin/rspec --require spec_helper
```

### Linting
```bash
# Run RuboCop on the codebase
bin/rubocop

# Run RuboCop with auto-correction
bin/rubocop -a

# Run RuboCop with unsafe auto-correction
bin/rubocop -A
```

### Build & Release
```bash
# Build the gem
gem build momocop.gemspec

# Install locally for testing
bundle exec rake install

# Update README files from templates
# DO NOT modify README.ja.md or README.md directly.
# You have to modify README.ja.md.erb or README.md.erb and execute following command to re-generate README files.
bundle exec rake readme:update
```

### Development Workflow
```bash
# Install dependencies
bundle install

# Run default tasks (specs + rubocop)
bundle exec rake

# Debug with console
bundle exec irb -r ./lib/momocop
```

## Architecture

### Core Structure

The gem consists of three main architectural layers:

1. **Cop Implementations** (`lib/rubocop/cop/momocop/`): Each cop is a separate class that inherits from RuboCop's base cop classes. They analyze Ruby AST nodes and report/correct violations.

2. **Helper Modules** (`lib/momocop/helpers/`):
   - `FactoryBotHelper`: Utilities for analyzing FactoryBot DSL patterns
   - `RailsHelper`: Rails-specific analysis utilities

3. **Extractors** (`lib/momocop/`):
   - `AssociationExtractor`: Extracts Rails model associations for FactoryBot validation
   - `EnumExtractor`: Parses Rails enum definitions for property validation

### Cop Categories

- **FactoryBot Cops**: Enforce conventions for factory definitions (naming, structure, associations)
- **RSpec Cops**: Enforce wording conventions for describe/context/example blocks
- **Layout Cops**: General formatting rules like comment spacing

### Integration Points

The gem integrates with RuboCop through:
- `ConfigInjector`: Automatically injects cop configurations
- Registration in `lib/momocop.rb` which requires all cops and helpers

### Testing Strategy

Each cop has a corresponding spec file that tests:
- Detection of violations using `expect_offense`
- Auto-correction behavior using `expect_correction`
- Edge cases and various Ruby syntax patterns
- **Private methods**: Test private methods using `send` method to achieve 100% code coverage
  - Example: `object.send(:private_method_name, arguments)`
  - This ensures all code paths are tested, including internal implementation details

When adding new cops:
1. Create the cop class in `lib/rubocop/cop/momocop/`
2. Create corresponding spec in `spec/rubocop/cop/momocop/`
3. Register the cop in the appropriate require statement
4. Update README templates if adding new cop documentation

### Code Coverage Policy

- **Target**: 100% line coverage for all files
- **Private Methods**: Must be tested using `send` method
- **Edge Cases**: All branches and conditions should be covered
- **Verification**: Run `bundle exec rspec --require spec_helper` to check coverage

## Ruby Version Support

Minimum Ruby version: 3.1.1
CI tests against Ruby: 3.1, 3.2, 3.3, 3.4
