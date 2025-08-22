#!/usr/bin/env ruby
# frozen_string_literal: true

require 'prism'
require_relative '../lib/prism_combo'

def test_combo_node(description, code)
  puts "\n" + ('=' * 60)
  puts "【#{description}】"
  puts '-' * 60
  puts "コード: #{code.strip}"
  puts '-' * 60

  result = Prism.parse(code)

  if result.success?
    # 最初のCallNodeを取得
    call_node = find_first_call_node(result.value)

    if call_node
      combo = PrismCombo::ComboNode.new(call_node)

      puts '基本情報:'
      puts "  メソッド名: #{combo.method_name}"
      puts "  フルパス: #{combo.full_method_path}"
      puts "  レシーバーあり: #{combo.has_receiver?}"
      puts "  レシーバー型: #{combo.receiver_type}"
      puts ''

      puts '引数情報:'
      puts "  引数あり: #{combo.has_arguments?}"
      puts "  引数数: #{combo.argument_count}"
      puts "  位置引数数: #{combo.positional_arguments.size}"
      puts "  キーワード引数あり: #{combo.has_keyword_arguments?}"
      puts "  括弧あり: #{combo.has_parentheses?}"

      if combo.has_arguments?
        args_info = PrismCombo::ArgumentsInfo.new(combo.node.arguments)
        puts "  引数タイプ: #{args_info.argument_types}"
        puts "  キーワード名: #{args_info.keyword_names}" if args_info.has_keywords?
      end
      puts ''

      puts 'ブロック情報:'
      puts "  ブロックあり: #{combo.has_block?}"
      if combo.has_block?
        puts "  ブロックタイプ: #{combo.block_type}"
        puts "  単一行: #{combo.single_line_block?}"
        puts "  複数行: #{combo.multi_line_block?}"
        puts "  ブロック引数: #{combo.block_parameters}"

        block_info = PrismCombo::BlockInfo.new(combo.block_node)
        puts "  ステートメント数: #{block_info.statement_count}"
        puts "  空: #{block_info.empty?}"
        puts "  return含む: #{block_info.contains_return?}"
      end
      puts ''

      puts 'その他:'
      puts "  Safe navigation: #{combo.safe_navigation?}"
      puts "  メソッドチェーン内: #{combo.in_method_chain?}"
      puts "  チェーン長: #{combo.chain_length}"
      puts "  チェーンメソッド: #{combo.chain_methods}"
      puts "  Procを引数に: #{combo.proc_argument?}"
      puts ''

      puts '特殊パターン検出:'
      puts "  FactoryBot: #{combo.factory_bot_call?}"
      puts "  RSpec matcher: #{combo.rspec_matcher?}"
      puts "  Rails query: #{combo.rails_query_method?}"
      puts "  Enumerable: #{combo.enumerable_method?}"

    else
      puts 'CallNodeが見つかりませんでした'
    end
  else
    puts "パースエラー: #{result.errors}"
  end

  puts '=' * 60
end

def find_first_call_node(node)
  return nil unless node
  return node if node.is_a?(Prism::CallNode)

  # ProgramNodeから始まる
  if node.is_a?(Prism::ProgramNode)
    return find_first_call_node(node.statements)
  end

  # StatementsNodeのbodyを探索
  if node.is_a?(Prism::StatementsNode)
    node.body.each do |child|
      result = find_first_call_node(child)
      return result if result
    end
  end

  nil
end

# テストケース実行
test_combo_node('シンプルなメソッド呼び出し', 'puts')

test_combo_node('引数ありメソッド呼び出し', "puts 'hello'")

test_combo_node('レシーバー付きメソッド呼び出し', 'user.name')

test_combo_node('メソッドチェーン', 'users.select { |u| u.active? }.map(&:email)')

test_combo_node('ブロック付きメソッド', <<~RUBY)
  items.each do |item|
    puts item
    process(item)
  end
RUBY

test_combo_node('キーワード引数', "create_user(name: 'Alice', age: 30, admin: true)")

test_combo_node('Safe navigation operator', 'user&.profile&.address')

test_combo_node('FactoryBot呼び出し', "create(:user, name: 'Bob')")

test_combo_node('RSpec matcher', 'expect(result).to eq(42)')

test_combo_node('Rails query', 'User.where(active: true).includes(:posts)')

test_combo_node('Enumerable メソッド', 'numbers.inject(0) { |sum, n| sum + n }')

test_combo_node('Proc引数', 'items.map(&:to_s)')

test_combo_node('複雑な引数', <<~RUBY)
  method_call(
    'literal',
    variable,
    :symbol,
    key: 'value'
  )
RUBY
