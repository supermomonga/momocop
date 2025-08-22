# PrismCombo

RubocopのカスタムCop開発を簡単にするための、Prism AST CallNodeのWrapperライブラリです。

## 概要

PrismComboは、RubyのコードをPrismでパースした際のCallNode（メソッド呼び出し）を簡単に分析できるようにするライブラリです。
複雑なAST構造を扱いやすくし、様々なメソッド呼び出しパターンを簡単に検出できます。

## 使い方

```ruby
require 'prism'
require 'prism_combo'

# コードをパース
result = Prism.parse("users.select { |u| u.active? }.map(&:email)")
call_node = # CallNodeを取得

# ComboNodeでラップ
combo = PrismCombo::ComboNode.new(call_node)

# 基本情報
combo.method_name         # => :map
combo.has_receiver?       # => true
combo.has_arguments?      # => false
combo.has_block?          # => true (BlockArgumentNodeもtrueになる)

# ブロック情報
combo.block_type          # => :brace or :do_end
combo.single_line_block?  # => true
combo.block_parameters    # => [:u]

# 引数情報
combo.argument_count      # => 0
combo.has_keyword_arguments? # => false
combo.proc_argument?      # => true (&:emailの場合)

# メソッドチェーン
combo.chain_length        # => 3
combo.chain_methods       # => [:users, :select, :map]

# 特殊パターン検出
combo.factory_bot_call?   # => false
combo.rspec_matcher?      # => false
combo.rails_query_method? # => false
combo.enumerable_method?  # => true
```

## 主な機能

### ComboNode

CallNodeをラップして以下の機能を提供：

- **基本情報**: メソッド名、レシーバー、フルパス
- **引数分析**: 引数の有無、個数、タイプ、キーワード引数
- **ブロック分析**: ブロックの有無、スタイル、パラメータ
- **メソッドチェーン**: チェーンの長さ、メソッド名リスト
- **特殊パターン検出**: FactoryBot、RSpec、Rails、Enumerable

### BlockInfo

ブロックの詳細情報を提供：

```ruby
block_info = PrismCombo::BlockInfo.new(combo.block_node)

block_info.style           # => :brace or :do_end
block_info.single_line?    # => true/false
block_info.parameter_names # => [:item, :index]
block_info.statement_count # => 3
block_info.contains_return? # => true/false
```

### ArgumentsInfo

引数の詳細情報を提供：

```ruby
args_info = PrismCombo::ArgumentsInfo.new(combo.node.arguments)

args_info.count            # => 3
args_info.positional_count # => 2
args_info.keyword_names    # => [:name, :age]
args_info.argument_types   # => [:string, :symbol, :keyword_hash]
args_info.contains_string? # => true
```

## Rubocopでの使用例

```ruby
module RuboCop
  module Cop
    module Custom
      class MyCustomCop < Base
        def on_send(node)
          # PrismのCallNodeに変換
          source = node.source
          result = Prism.parse(source)
          call_node = find_call_node(result.value)

          # ComboNodeでラップ
          combo = PrismCombo::ComboNode.new(call_node)

          # FactoryBotの呼び出しをチェック
          if combo.factory_bot_call? && !combo.has_parentheses?
            add_offense(node, message: "Use parentheses for FactoryBot methods")
          end

          # 長いメソッドチェーンをチェック
          if combo.chain_length > 3
            add_offense(node, message: "Method chain too long (#{combo.chain_length} methods)")
          end
        end
      end
    end
  end
end
```

## 対応パターン

- 引数なしメソッド呼び出し
- 引数ありメソッド呼び出し（位置引数、キーワード引数）
- ブロック付きメソッド（`{}` / `do...end`）
- メソッドチェーン
- Safe navigation operator (`&.`)
- Proc引数 (`&:symbol`)
- 特殊なDSL（FactoryBot、RSpec、Rails）

## ライセンス

MIT Lisence
