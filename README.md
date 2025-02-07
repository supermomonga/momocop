English | [日本語](./README.ja.md)

# momocop

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

Momocop/FactoryBotClassExistence:
  Enabled: true
Momocop/FactoryBotConsistentFileName:
  Enabled: true
Momocop/FactoryBotInlineAssociation:
  Enabled: true
Momocop/FactoryBotMissingAssociations:
  Enabled: true
Momocop/FactoryBotMissingClassOption:
  Enabled: true
Momocop/FactoryBotMissingProperties:
  Enabled: true
Momocop/FactoryBotPropertyOrder:
  Enabled: true
Momocop/FactoryBotSingleDefinePerFile:
  Enabled: true
Momocop/FactoryBotSingleFactoryPerDefine:
  Enabled: true
Momocop/FactoryBotSingularFactoryName:
  Enabled: true
Momocop/Layout/LeadingCommentSpace:
  Enabled: true
Momocop/RspecDescribeTextPattern:
  Enabled: true
Momocop/RspecItTextPattern:
  Enabled: true
```

## Cops

|Cop|Rails|FactoryBot|
|---|:-:|:-:|
|[`Momocop/FactoryBotClassExistence`](lib/rubocop/cop/momocop/factory_bot_class_existence.rb)|:white_check_mark:|:white_check_mark:|
|[`Momocop/FactoryBotConsistentFileName`](lib/rubocop/cop/momocop/factory_bot_consistent_file_name.rb)|:white_check_mark:|:white_check_mark:|
|[`Momocop/FactoryBotInlineAssociation`](lib/rubocop/cop/momocop/factory_bot_inline_association.rb)|:white_check_mark:|:white_check_mark:|
|[`Momocop/FactoryBotMissingAssociations`](lib/rubocop/cop/momocop/factory_bot_missing_associations.rb)|:white_check_mark:|:white_check_mark:|
|[`Momocop/FactoryBotMissingClassOption`](lib/rubocop/cop/momocop/factory_bot_missing_class_option.rb)|:white_check_mark:|:white_check_mark:|
|[`Momocop/FactoryBotMissingProperties`](lib/rubocop/cop/momocop/factory_bot_missing_properties.rb)|:white_check_mark:|:white_check_mark:|
|[`Momocop/FactoryBotPropertyOrder`](lib/rubocop/cop/momocop/factory_bot_property_order.rb)|:white_check_mark:|:white_check_mark:|
|[`Momocop/FactoryBotSingleDefinePerFile`](lib/rubocop/cop/momocop/factory_bot_single_define_per_file.rb)|:white_check_mark:|:white_check_mark:|
|[`Momocop/FactoryBotSingleFactoryPerDefine`](lib/rubocop/cop/momocop/factory_bot_single_factory_per_define.rb)|:white_check_mark:|:white_check_mark:|
|[`Momocop/FactoryBotSingularFactoryName`](lib/rubocop/cop/momocop/factory_bot_singular_factory_name.rb)|:white_check_mark:|:white_check_mark:|
|[`Momocop/Layout/LeadingCommentSpace`](lib/rubocop/cop/momocop/layout/leading_comment_space.rb)|||
|[`Momocop/RspecDescribeTextPattern`](lib/rubocop/cop/momocop/rspec_describe_text_pattern.rb)|||
|[`Momocop/RspecItTextPattern`](lib/rubocop/cop/momocop/rspec_it_text_pattern.rb)|||

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/supermomonga/momocop. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/supermomonga/momocop/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Momocop project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/supermomonga/momocop/blob/main/CODE_OF_CONDUCT.md).
