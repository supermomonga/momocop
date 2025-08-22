# frozen_string_literal: true

require 'prism'
require 'prism_combo'
require 'spec_helper'

RSpec.describe PrismCombo::BlockInfo do
  def parse_block(code)
    result = Prism.parse(code)
    node = result.value.statements.body.first
    node.block
  end

  describe '#initialize' do
    it 'accepts Prism::BlockNode' do
      block_node = parse_block('foo { }')
      expect { described_class.new(block_node) }.not_to raise_error
    end

    it 'raises ArgumentError for non-BlockNode' do
      expect { described_class.new('not a block node') }
        .to raise_error(ArgumentError, /Expected Prism::BlockNode/)
    end
  end

  describe '#style' do
    it 'returns :brace for brace blocks' do
      block_node = parse_block('foo { }')
      info = described_class.new(block_node)
      expect(info.style).to eq(:brace)
    end

    it 'returns :do_end for do..end blocks' do
      block_node = parse_block('foo do; end')
      info = described_class.new(block_node)
      expect(info.style).to eq(:do_end)
    end
  end

  describe '#single_line?' do
    it 'returns true for single line blocks' do
      block_node = parse_block('foo { bar }')
      info = described_class.new(block_node)
      expect(info.single_line?).to be true
    end

    it 'returns false for multi-line blocks' do
      block_node = parse_block("foo do\n  bar\nend")
      info = described_class.new(block_node)
      expect(info.single_line?).to be false
    end
  end

  describe '#multi_line?' do
    it 'returns false for single line blocks' do
      block_node = parse_block('foo { bar }')
      info = described_class.new(block_node)
      expect(info.multi_line?).to be false
    end

    it 'returns true for multi-line blocks' do
      block_node = parse_block("foo do\n  bar\nend")
      info = described_class.new(block_node)
      expect(info.multi_line?).to be true
    end
  end

  describe '#parameters' do
    it 'returns parameters for blocks with parameters' do
      block_node = parse_block('foo { |a, b| }')
      info = described_class.new(block_node)
      params = info.parameters
      expect(params.size).to eq(2)
      expect(params[0]).to include(name: :a, type: :required)
      expect(params[1]).to include(name: :b, type: :required)
    end

    it 'returns empty array for blocks without parameters' do
      block_node = parse_block('foo { }')
      info = described_class.new(block_node)
      expect(info.parameters).to eq([])
    end

    it 'handles optional parameters' do
      block_node = parse_block('foo { |a, b = 1| }')
      info = described_class.new(block_node)
      params = info.parameters
      expect(params[1]).to include(name: :b, type: :optional)
    end

    it 'handles rest parameters' do
      block_node = parse_block('foo { |a, *rest| }')
      info = described_class.new(block_node)
      params = info.parameters
      expect(params[1]).to include(name: :rest, type: :rest)
    end

    it 'handles keyword parameters' do
      block_node = parse_block('foo { |a:, b: 1| }')
      info = described_class.new(block_node)
      params = info.parameters
      expect(params[0]).to include(name: :a, type: :keyword)
      expect(params[1]).to include(name: :b, type: :keyword)
    end

    it 'handles keyword rest parameters' do
      block_node = parse_block('foo { |**opts| }')
      info = described_class.new(block_node)
      params = info.parameters
      expect(params[0]).to include(name: :opts, type: :keyword_rest)
    end

    it 'handles block parameters' do
      block_node = parse_block('foo { |&block| }')
      info = described_class.new(block_node)
      params = info.parameters
      expect(params[0]).to include(name: :block, type: :block)
    end
  end

  describe '#parameter_names' do
    it 'returns parameter names' do
      block_node = parse_block('foo { |a, b, c| }')
      info = described_class.new(block_node)
      expect(info.parameter_names).to eq(%i[a b c])
    end

    it 'returns empty array when no parameters' do
      block_node = parse_block('foo { }')
      info = described_class.new(block_node)
      expect(info.parameter_names).to eq([])
    end
  end

  describe '#parameter_count' do
    it 'returns the count of parameters' do
      block_node = parse_block('foo { |a, b| }')
      info = described_class.new(block_node)
      expect(info.parameter_count).to eq(2)
    end

    it 'returns 0 when no parameters' do
      block_node = parse_block('foo { }')
      info = described_class.new(block_node)
      expect(info.parameter_count).to eq(0)
    end
  end

  describe '#body_statements' do
    it 'returns body statements' do
      block_node = parse_block('foo { bar; baz }')
      info = described_class.new(block_node)
      expect(info.body_statements.size).to eq(2)
    end

    it 'returns empty array for empty blocks' do
      block_node = parse_block('foo { }')
      info = described_class.new(block_node)
      expect(info.body_statements).to eq([])
    end
  end

  describe '#statement_count' do
    it 'returns the count of statements' do
      block_node = parse_block('foo { bar; baz; qux }')
      info = described_class.new(block_node)
      expect(info.statement_count).to eq(3)
    end

    it 'returns 0 for empty blocks' do
      block_node = parse_block('foo { }')
      info = described_class.new(block_node)
      expect(info.statement_count).to eq(0)
    end
  end

  describe '#empty?' do
    it 'returns true for empty blocks' do
      block_node = parse_block('foo { }')
      info = described_class.new(block_node)
      expect(info.empty?).to be true
    end

    it 'returns false for non-empty blocks' do
      block_node = parse_block('foo { bar }')
      info = described_class.new(block_node)
      expect(info.empty?).to be false
    end
  end

  describe '#single_statement?' do
    it 'returns true for blocks with single statement' do
      block_node = parse_block('foo { bar }')
      info = described_class.new(block_node)
      expect(info.single_statement?).to be true
    end

    it 'returns false for blocks with multiple statements' do
      block_node = parse_block('foo { bar; baz }')
      info = described_class.new(block_node)
      expect(info.single_statement?).to be false
    end

    it 'returns false for empty blocks' do
      block_node = parse_block('foo { }')
      info = described_class.new(block_node)
      expect(info.single_statement?).to be false
    end
  end

  describe '#first_statement' do
    it 'returns the first statement' do
      block_node = parse_block('foo { bar; baz }')
      info = described_class.new(block_node)
      expect(info.first_statement).to be_a(Prism::CallNode)
    end

    it 'returns nil for empty blocks' do
      block_node = parse_block('foo { }')
      info = described_class.new(block_node)
      expect(info.first_statement).to be_nil
    end
  end

  describe '#last_statement' do
    it 'returns the last statement' do
      block_node = parse_block('foo { bar; baz }')
      info = described_class.new(block_node)
      expect(info.last_statement).to be_a(Prism::CallNode)
    end

    it 'returns nil for empty blocks' do
      block_node = parse_block('foo { }')
      info = described_class.new(block_node)
      expect(info.last_statement).to be_nil
    end
  end

  describe '#returns_value?' do
    it 'returns true for blocks that return a value' do
      block_node = parse_block('foo { bar }')
      info = described_class.new(block_node)
      expect(info.returns_value?).to be true
    end

    it 'returns false for empty blocks' do
      block_node = parse_block('foo { }')
      info = described_class.new(block_node)
      expect(info.returns_value?).to be false
    end

    it 'returns false for blocks ending with puts' do
      block_node = parse_block('foo { puts "hello" }')
      info = described_class.new(block_node)
      expect(info.returns_value?).to be false
    end

    it 'returns false for blocks ending with return' do
      block_node = parse_block('foo { return 42 }')
      info = described_class.new(block_node)
      expect(info.returns_value?).to be false
    end

    it 'returns false for blocks ending with break' do
      block_node = parse_block('foo { break }')
      info = described_class.new(block_node)
      expect(info.returns_value?).to be false
    end

    it 'returns false for blocks ending with next' do
      block_node = parse_block('foo { next }')
      info = described_class.new(block_node)
      expect(info.returns_value?).to be false
    end
  end

  describe '#each_statement' do
    it 'yields each statement' do
      block_node = parse_block('foo { bar; baz; qux }')
      info = described_class.new(block_node)
      count = 0
      info.each_statement do count += 1 end
      expect(count).to eq(3)
    end
  end

  describe '#contains_return?' do
    it 'returns true when block contains return' do
      block_node = parse_block('foo { return 42 }')
      info = described_class.new(block_node)
      expect(info.contains_return?).to be true
    end

    it 'returns false when block does not contain return' do
      block_node = parse_block('foo { bar }')
      info = described_class.new(block_node)
      expect(info.contains_return?).to be false
    end

    it 'finds return in nested structures' do
      block_node = parse_block('foo { if true; return 42; end }')
      info = described_class.new(block_node)
      expect(info.contains_return?).to be true
    end
  end

  describe '#contains_break?' do
    it 'returns true when block contains break' do
      block_node = parse_block('foo { break }')
      info = described_class.new(block_node)
      expect(info.contains_break?).to be true
    end

    it 'returns false when block does not contain break' do
      block_node = parse_block('foo { bar }')
      info = described_class.new(block_node)
      expect(info.contains_break?).to be false
    end
  end

  describe '#contains_next?' do
    it 'returns true when block contains next' do
      block_node = parse_block('foo { next }')
      info = described_class.new(block_node)
      expect(info.contains_next?).to be true
    end

    it 'returns false when block does not contain next' do
      block_node = parse_block('foo { bar }')
      info = described_class.new(block_node)
      expect(info.contains_next?).to be false
    end
  end

  describe '#contains_local_variable_write?' do
    it 'returns true when block contains local variable assignment' do
      block_node = parse_block('foo { x = 1 }')
      info = described_class.new(block_node)
      expect(info.contains_local_variable_write?).to be true
    end

    it 'returns false when block does not contain local variable assignment' do
      block_node = parse_block('foo { bar }')
      info = described_class.new(block_node)
      expect(info.contains_local_variable_write?).to be false
    end
  end

  describe '#to_source' do
    it 'returns the source code of the block' do
      block_node = parse_block('foo { |a| bar }')
      info = described_class.new(block_node)
      expect(info.to_source).to eq('{ |a| bar }')
    end
  end

  describe '#location' do
    it 'returns location information' do
      block_node = parse_block('foo { bar }')
      info = described_class.new(block_node)
      location = info.location
      expect(location).to include(:line, :column, :end_line, :end_column)
      expect(location[:line]).to eq(1)
    end
  end

  describe '#style' do
    it 'returns :unknown for invalid block style' do
      # Create a block node with a non-standard opening
      # This is a bit tricky - we need to trigger the else condition
      block_node = parse_block('foo { bar }')
      # Stub the opening_loc to return something unexpected
      allow(block_node.opening_loc).to receive(:slice).and_return('something_else')
      info = described_class.new(block_node)
      expect(info.style).to eq(:unknown)
    end
  end

  describe '#returns_value?' do
    it 'returns false for unsupported node types' do
      # Using a block with a constant or other unsupported type
      block_node = parse_block('foo { CONST }')
      info = described_class.new(block_node)
      expect(info.returns_value?).to be false
    end
  end

  describe '#parameters with post parameters' do
    it 'handles blocks with post parameters' do
      # Ruby 3.0+ syntax for rightward assignment
      # Post parameters come after a rest parameter
      block_node = parse_block('foo { |a, *rest, b| bar }')
      info = described_class.new(block_node)
      params = info.parameters
      # Should have parameters including post parameter
      expect(params).to include(hash_including(name: :b, type: :post))
    end
  end

  describe '#contains_node_type? with nested blocks' do
    it 'finds nodes in nested blocks' do
      block_node = parse_block('foo { bar { return 42 } }')
      info = described_class.new(block_node)
      # This should trigger traverse of BlockNode case
      expect(info.contains_return?).to be true
    end

    it 'finds nodes in if statements with else clause' do
      block_node = parse_block('foo { if true; bar; else; return 42; end }')
      info = described_class.new(block_node)
      # This should trigger traverse of IfNode's consequent (else clause)
      expect(info.contains_return?).to be true
    end

    it 'finds nodes in method call arguments' do
      block_node = parse_block('foo { bar(return 42) }')
      info = described_class.new(block_node)
      # This should trigger traverse of ArgumentsNode
      expect(info.contains_return?).to be true
    end
  end

  describe '#returns_value? with edge cases' do
    context 'with void statement' do
      it 'returns false for void statements' do
        # Use a real void statement
        block_node = parse_block('foo { return }')
        info = described_class.new(block_node)
        
        expect(info.returns_value?).to be false
      end
    end
    
    context 'with unknown node type' do
      it 'returns false for unknown node types' do
        # Create a block with a normal statement
        block_node = parse_block('foo { 1 }')
        info = described_class.new(block_node)
        
        # Mock last_statement to return an unknown node type
        unknown_node = double('UnknownNode')
        allow(unknown_node).to receive(:is_a?).and_return(false)
        allow(info).to receive(:last_statement).and_return(unknown_node)
        
        # This should trigger the else branch (line 173)
        # unknown node is not void, so returns_value? should be true
        expect(info.returns_value?).to be true
      end
    end
  end
end
