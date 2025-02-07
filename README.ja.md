[English](./README.md) | 日本語

# momocop

[![Spec](https://github.com/supermomonga/momocop/actions/workflows/spec.yml/badge.svg)](https://github.com/supermomonga/momocop/actions/workflows/spec.yml) [![Gem Version](https://badge.fury.io/rb/momocop.svg)](https://badge.fury.io/rb/momocop)

Momocopは、規約ベースのOpinionatedな[RuboCop](https://github.com/rubocop/rubocop)カスタムCopを提供します。

## インストール

`momocop`をGemfileに追加してください。

```rb
# Gemfile
gem 'momocop', require: false
```

## 使用方法

`.rubocop.yml`を編集して、`momocop`をrequireしてください。

すべてのCopはデフォルトで無効になっているため、利用したいCopを有効にしてください。

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

## Cop一覧

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

## 貢献

GitHubの https://github.com/supermomonga/momocop でのバグ報告やプルリクエストは歓迎します。このプロジェクトは安全で、協力的な空間であることを目指しており、貢献者は[行動規範](https://github.com/supermomonga/momocop/blob/main/CODE_OF_CONDUCT.md)に従うことが求められます。

## ライセンス

このgemは[MITライセンス](https://opensource.org/licenses/MIT)の条件の下でオープンソースとして利用可能です。

## 行動規範

Momocopプロジェクトのコードベース、イシュートラッカー、チャットルーム、およびメーリングリストにおいて交流する全員は、[行動規範](https://github.com/supermomonga/momocop/blob/main/CODE_OF_CONDUCT.md)に従うことが期待されます。
