#!/usr/bin/env ruby
# frozen_string_literal: true

require 'prism'

code = "puts 'hello'"
result = Prism.parse(code)

puts "コード: #{code}"
puts 'AST:'
pp result.value

puts "\nステートメント:"
pp result.value.statements

puts "\nボディ:"
pp result.value.statements.body

puts "\n最初の要素:"
first = result.value.statements.body.first
pp first

puts "\nCallNodeか？: #{first.is_a?(Prism::CallNode)}"
