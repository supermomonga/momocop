#!/usr/bin/env ruby
# frozen_string_literal: true

require 'prism'

def analyze_code(description, code)
  puts "\n" + ('=' * 60)
  puts "【#{description}】"
  puts '-' * 60
  puts 'コード:'
  puts code
  puts '-' * 60
  puts 'AST構造:'

  result = Prism.parse(code)

  if result.success?
    pp result.value
  else
    puts "パースエラー: #{result.errors}"
  end

  puts '=' * 60
end

# 1. 引数なしのメソッド呼び出し
analyze_code('引数なしのメソッド呼び出し', <<~RUBY)
  puts
  foo
  object.bar
RUBY

# 2. 引数ありのメソッド呼び出し
analyze_code('引数ありのメソッド呼び出し', <<~RUBY)
  puts "hello"
  foo(1, 2, 3)
  object.bar(:symbol, "string", 123)
  method_with_kwargs(name: "value", count: 10)
RUBY

# 3. ブロックあり（ブロック内のコードが1行）
analyze_code('ブロックあり（1行）', <<~RUBY)
  items.each { |item| puts item }
  5.times { puts "hello" }
  array.map { |x| x * 2 }
RUBY

# 4. ブロックあり（ブロック内のコードが複数行）
analyze_code('ブロックあり（複数行）', <<~RUBY)
  items.each do |item|
    puts item
    process(item)
    save_result(item)
  end

  File.open("test.txt") do |file|
    content = file.read
    puts content
  end
RUBY

# 5. 追加パターン：引数とブロックの組み合わせ
analyze_code('引数とブロックの組み合わせ', <<~RUBY)
  array.inject(0) { |sum, n| sum + n }

  define_method(:hello) do |name|
    puts "Hello, \#{name}!"
  end

  items.select { |item| item.valid? }.map(&:name)
RUBY

# 6. 追加パターン：メソッドチェーン
analyze_code('メソッドチェーン', <<~RUBY)
  users
    .select { |u| u.active? }
    .map(&:email)
    .sort
    .uniq
RUBY

# 7. 追加パターン：safe navigation operator
analyze_code('Safe navigation operator', <<~RUBY)
  user&.name
  account&.profile&.address
  obj&.method_with_args(1, 2, 3)
RUBY
