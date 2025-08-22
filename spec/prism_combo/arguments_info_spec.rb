# frozen_string_literal: true

require 'prism'
require 'prism_combo'
require 'spec_helper'

RSpec.describe PrismCombo::ArgumentsInfo do
  def parse_arguments(code)
    result = Prism.parse(code)
    node = result.value.statements.body.first
    node.arguments
  end

  describe '#initialize' do
    it 'accepts Prism::ArgumentsNode' do
      args_node = parse_arguments('foo(1, 2)')
      expect { described_class.new(args_node) }.not_to raise_error
    end

    it 'raises ArgumentError for non-ArgumentsNode' do
      expect { described_class.new('not an arguments node') }
        .to raise_error(ArgumentError, /Expected Prism::ArgumentsNode/)
    end
  end

  describe '#arguments' do
    it 'returns the arguments array' do
      args_node = parse_arguments('foo(1, 2, 3)')
      info = described_class.new(args_node)
      expect(info.arguments.size).to eq(3)
    end
  end

  describe '#count' do
    it 'returns the number of arguments' do
      args_node = parse_arguments('foo(1, 2, 3)')
      info = described_class.new(args_node)
      expect(info.count).to eq(3)
    end
  end

  describe '#empty?' do
    it 'returns false when arguments exist' do
      args_node = parse_arguments('foo(1)')
      info = described_class.new(args_node)
      expect(info.empty?).to be false
    end
  end

  describe '#positional_arguments' do
    it 'returns only positional arguments' do
      args_node = parse_arguments('foo(1, 2, key: 3)')
      info = described_class.new(args_node)
      expect(info.positional_arguments.size).to eq(2)
    end

    it 'excludes keyword arguments' do
      args_node = parse_arguments('foo(key1: 1, key2: 2)')
      info = described_class.new(args_node)
      expect(info.positional_arguments).to be_empty
    end
  end

  describe '#positional_count' do
    it 'returns the count of positional arguments' do
      args_node = parse_arguments('foo(1, 2, key: 3)')
      info = described_class.new(args_node)
      expect(info.positional_count).to eq(2)
    end
  end

  describe '#keyword_arguments' do
    it 'returns only keyword arguments' do
      args_node = parse_arguments('foo(1, key1: 2, key2: 3)')
      info = described_class.new(args_node)
      expect(info.keyword_arguments.size).to eq(1)
    end
  end

  describe '#keyword_count' do
    it 'returns the count of keyword arguments' do
      args_node = parse_arguments('foo(key1: 1, key2: 2)')
      info = described_class.new(args_node)
      expect(info.keyword_count).to eq(1)
    end
  end

  describe '#has_keywords?' do
    it 'returns true when keyword arguments exist' do
      args_node = parse_arguments('foo(key: 1)')
      info = described_class.new(args_node)
      expect(info.has_keywords?).to be true
    end

    it 'returns false when no keyword arguments' do
      args_node = parse_arguments('foo(1, 2)')
      info = described_class.new(args_node)
      expect(info.has_keywords?).to be false
    end
  end

  describe '#keyword_names' do
    it 'returns an array of keyword names' do
      args_node = parse_arguments('foo(key1: 1, key2: 2)')
      info = described_class.new(args_node)
      expect(info.keyword_names).to eq(%i[key1 key2])
    end

    it 'returns empty array when no keywords' do
      args_node = parse_arguments('foo(1, 2)')
      info = described_class.new(args_node)
      expect(info.keyword_names).to eq([])
    end
  end

  describe '#block_arguments' do
    it 'returns empty array when no block arguments' do
      args_node = parse_arguments('foo(1, 2)')
      info = described_class.new(args_node)
      expect(info.block_arguments).to eq([])
    end
  end

  describe '#has_block_argument?' do
    it 'returns false when no block argument' do
      args_node = parse_arguments('foo(1)')
      info = described_class.new(args_node)
      expect(info.has_block_argument?).to be false
    end
  end

  describe '#splat_arguments' do
    it 'returns splat arguments' do
      args_node = parse_arguments('foo(*args)')
      info = described_class.new(args_node)
      expect(info.splat_arguments.size).to eq(1)
    end
  end

  describe '#has_splat?' do
    it 'returns true when splat argument exists' do
      args_node = parse_arguments('foo(*args)')
      info = described_class.new(args_node)
      expect(info.has_splat?).to be true
    end

    it 'returns false when no splat argument' do
      args_node = parse_arguments('foo(1)')
      info = described_class.new(args_node)
      expect(info.has_splat?).to be false
    end
  end

  describe '#literal_arguments' do
    it 'returns only literal arguments' do
      args_node = parse_arguments('foo(1, "string", variable)')
      info = described_class.new(args_node)
      expect(info.literal_arguments.size).to eq(2)
    end
  end

  describe '#literal_values' do
    it 'returns the values of literal arguments' do
      args_node = parse_arguments('foo(1, "hello", :symbol)')
      info = described_class.new(args_node)
      expect(info.literal_values).to eq([1, 'hello', :symbol])
    end
  end

  describe '#argument_types' do
    it 'returns the types of all arguments' do
      args_node = parse_arguments('foo(1, "str", :sym, true, false, nil, /regex/, [1])')
      info = described_class.new(args_node)
      types = info.argument_types
      expect(types).to eq(%i[integer string symbol true false nil regex array])
    end

    it 'handles keyword arguments' do
      args_node = parse_arguments('foo(a: 1)')
      info = described_class.new(args_node)
      types = info.argument_types
      expect(types).to include(:keyword_hash)
    end
  end

  describe '#each_argument' do
    it 'yields each argument' do
      args_node = parse_arguments('foo(1, 2, 3)')
      info = described_class.new(args_node)
      count = 0
      info.each_argument do count += 1 end
      expect(count).to eq(3)
    end
  end

  describe '#each_positional' do
    it 'yields each positional argument' do
      args_node = parse_arguments('foo(1, 2, key: 3)')
      info = described_class.new(args_node)
      count = 0
      info.each_positional do count += 1 end
      expect(count).to eq(2)
    end
  end

  describe '#each_keyword' do
    it 'yields each keyword argument' do
      args_node = parse_arguments('foo(1, key1: 2, key2: 3)')
      info = described_class.new(args_node)
      count = 0
      info.each_keyword do count += 1 end
      expect(count).to eq(1)
    end
  end

  describe '#first_argument' do
    it 'returns the first argument' do
      args_node = parse_arguments('foo(1, 2, 3)')
      info = described_class.new(args_node)
      expect(info.first_argument).to be_a(Prism::IntegerNode)
    end
  end

  describe '#last_argument' do
    it 'returns the last argument' do
      args_node = parse_arguments('foo(1, 2, 3)')
      info = described_class.new(args_node)
      expect(info.last_argument).to be_a(Prism::IntegerNode)
    end
  end

  describe '#argument_at' do
    it 'returns the argument at specified index' do
      args_node = parse_arguments('foo(1, 2, 3)')
      info = described_class.new(args_node)
      arg = info.argument_at(1)
      expect(arg).to be_a(Prism::IntegerNode)
      expect(arg.value).to eq(2)
    end

    it 'returns nil for out of bounds index' do
      args_node = parse_arguments('foo(1)')
      info = described_class.new(args_node)
      expect(info.argument_at(5)).to be_nil
    end
  end

  describe '#contains_heredoc?' do
    it 'returns true when heredoc argument exists' do
      code = 'foo(<<~HEREDOC)'
      args_node = parse_arguments(code)
      info = described_class.new(args_node)
      expect(info.contains_heredoc?).to be true
    end

    it 'returns false when no heredoc argument' do
      args_node = parse_arguments('foo("string")')
      info = described_class.new(args_node)
      expect(info.contains_heredoc?).to be false
    end
  end

  describe '#contains_regex?' do
    it 'returns true when regex argument exists' do
      args_node = parse_arguments('foo(/pattern/)')
      info = described_class.new(args_node)
      expect(info.contains_regex?).to be true
    end

    it 'returns false when no regex argument' do
      args_node = parse_arguments('foo("string")')
      info = described_class.new(args_node)
      expect(info.contains_regex?).to be false
    end
  end

  describe '#contains_symbol?' do
    it 'returns true when symbol argument exists' do
      args_node = parse_arguments('foo(:symbol)')
      info = described_class.new(args_node)
      expect(info.contains_symbol?).to be true
    end

    it 'returns false when no symbol argument' do
      args_node = parse_arguments('foo("string")')
      info = described_class.new(args_node)
      expect(info.contains_symbol?).to be false
    end
  end

  describe '#contains_string?' do
    it 'returns true when string argument exists' do
      args_node = parse_arguments('foo("string")')
      info = described_class.new(args_node)
      expect(info.contains_string?).to be true
    end

    it 'returns false when no string argument' do
      args_node = parse_arguments('foo(123)')
      info = described_class.new(args_node)
      expect(info.contains_string?).to be false
    end
  end

  describe '#contains_interpolation?' do
    it 'returns true when interpolated string exists' do
      args_node = parse_arguments('foo("hello #{world}")')
      info = described_class.new(args_node)
      expect(info.contains_interpolation?).to be true
    end

    it 'returns false when no interpolated string' do
      args_node = parse_arguments('foo("string")')
      info = described_class.new(args_node)
      expect(info.contains_interpolation?).to be false
    end
  end

  describe '#to_source' do
    it 'returns the source code of arguments' do
      args_node = parse_arguments('foo(1, 2, 3)')
      info = described_class.new(args_node)
      expect(info.to_source).to eq('1, 2, 3')
    end
  end

  describe '#location' do
    it 'returns location information' do
      args_node = parse_arguments('foo(1, 2)')
      info = described_class.new(args_node)
      location = info.location
      expect(location).to include(:line, :column, :end_line, :end_column)
      expect(location[:line]).to eq(1)
    end
  end

  describe '#literal_values with various types' do
    it 'returns true for TrueNode' do
      args_node = parse_arguments('foo(true)')
      info = described_class.new(args_node)
      expect(info.literal_values).to eq([true])
    end

    it 'returns false for FalseNode' do
      args_node = parse_arguments('foo(false)')
      info = described_class.new(args_node)
      expect(info.literal_values).to eq([false])
    end

    it 'returns nil for NilNode' do
      args_node = parse_arguments('foo(nil)')
      info = described_class.new(args_node)
      expect(info.literal_values).to eq([nil])
    end

    it 'returns regex for RegularExpressionNode' do
      args_node = parse_arguments('foo(/pattern/)')
      info = described_class.new(args_node)
      expect(info.literal_values.first).to eq('pattern')
    end
  end

  describe '#argument_types with various types' do
    it 'returns :float for FloatNode' do
      args_node = parse_arguments('foo(1.5)')
      info = described_class.new(args_node)
      expect(info.argument_types).to eq([:float])
    end

    it 'returns :hash for HashNode' do
      args_node = parse_arguments('foo({a: 1})')
      info = described_class.new(args_node)
      expect(info.argument_types).to eq([:hash])
    end

    it 'returns :call for CallNode' do
      args_node = parse_arguments('foo(bar)')
      info = described_class.new(args_node)
      expect(info.argument_types).to eq([:call])
    end

    it 'returns :local_variable for LocalVariableReadNode' do
      code = 'x = 1; foo(x)'
      result = Prism.parse(code)
      node = result.value.statements.body.last
      args_node = node.arguments
      info = described_class.new(args_node)
      expect(info.argument_types).to eq([:local_variable])
    end

    it 'returns :instance_variable for InstanceVariableReadNode' do
      args_node = parse_arguments('foo(@var)')
      info = described_class.new(args_node)
      expect(info.argument_types).to eq([:instance_variable])
    end

    it 'returns :constant for ConstantReadNode' do
      args_node = parse_arguments('foo(CONST)')
      info = described_class.new(args_node)
      expect(info.argument_types).to eq([:constant])
    end

    it 'returns :splat for SplatNode' do
      args_node = parse_arguments('foo(*args)')
      info = described_class.new(args_node)
      expect(info.argument_types).to eq([:splat])
    end

    it 'returns :unknown for unsupported node type' do
      # Using a lambda as argument creates a more complex node
      args_node = parse_arguments('foo(-> { x })')
      info = described_class.new(args_node)
      expect(info.argument_types).to eq([:unknown])
    end
  end

  describe '#keyword_names with AssocNode' do
    it 'handles single AssocNode' do
      code = 'foo(**{key: 1})'
      result = Prism.parse(code)
      node = result.value.statements.body.first
      args_node = node.arguments
      info = described_class.new(args_node)
      # The keyword_names method processes keyword arguments
      names = info.keyword_names
      expect(names).to be_an(Array)
    end

    it 'handles edge cases in keyword extraction' do
      # Test case that would trigger the else branch
      code = 'foo(1, 2, 3)'
      result = Prism.parse(code)
      node = result.value.statements.body.first
      args_node = node.arguments
      info = described_class.new(args_node)
      names = info.keyword_names
      expect(names).to eq([])
    end
  end
  describe '#argument_types with BlockArgumentNode' do
    # BlockArgumentNode doesn't appear in normal arguments
    # Testing the default case
    it 'handles unknown node types' do
      code = 'foo(1)'
      result = Prism.parse(code)
      node = result.value.statements.body.first
      args_node = node.arguments
      info = described_class.new(args_node)
      
      # Create a mock object that doesn't match any known type
      unknown_arg = double('UnknownNode')
      allow(unknown_arg).to receive(:is_a?).and_return(false)
      
      # Test the argument_type method directly
      type = info.send(:argument_type, unknown_arg)
      expect(type).to eq(:unknown)
    end
  end
end
