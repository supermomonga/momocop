# Momocop

[![Spec](https://github.com/supermomonga/momocop/actions/workflows/spec.yml/badge.svg)](https://github.com/supermomonga/momocop/actions/workflows/spec.yml) [![Gem Version](https://badge.fury.io/rb/momocop.svg)](https://badge.fury.io/rb/momocop)

Momocop is highly opinionated custom cops for [RuboCop](https://github.com/rubocop/rubocop).

## Installation

Add `momocop` to your Gemfile.

```rb
# Gemfile
gem 'momocop', require: false
```

## Usage

Edit `.rubocop.yml` to require `momocop` and enable the cops you want.

All cops are disabled by default.

```yaml
# .rubocop.yaml
require:
  - momocop

Momocop/FactoryBotRailsFactoryAssociationsCoverage:
  Enabled: true
```

## Cops

|Cop|Rails|FactoryBot|
|---|:-:|:-:|
|[`Momocop/FactoryBotRailsClassName`](lib/rubocop/cop/momocop/factory_bot_rails_class_name.rb)|:white_check_mark:|:white_check_mark:|
|[`Momocop/FactoryBotRailsClassOptionSpecified`](lib/rubocop/cop/momocop/factory_bot_rails_class_option_specified.rb)|:white_check_mark:|:white_check_mark:|
|[`Momocop/FactoryBotRailsFactoryAssociationsCoverage`](lib/rubocop/cop/momocop/factory_bot_rails_factory_associations_coverage.rb)|:white_check_mark:|:white_check_mark:|
|[`Momocop/FactoryBotRailsFactoryPropertiesCoverage`](lib/rubocop/cop/momocop/factory_bot_rails_factory_properties_coverage.rb)|:white_check_mark:|:white_check_mark:|

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/supermomonga/momocop. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/supermomonga/momocop/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Momocop project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/supermomonga/momocop/blob/main/CODE_OF_CONDUCT.md).
