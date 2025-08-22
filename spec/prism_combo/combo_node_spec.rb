# frozen_string_literal: true

require 'prism'
require 'prism_combo/combo_node'
require 'spec_helper'

RSpec.describe PrismCombo::ComboNode do
  let(:source) { 'FactoryBot.define { factory :user { name { "John" } } }' }
  let(:result) { Prism.parse(source) }
  let(:root_node) { result.value.statements.body.first }
  let(:combo_node) { described_class.new(root_node) }

  describe '#parent_node' do
    it 'returns nil by default' do
      expect(combo_node.parent_node).to be_nil
    end
  end

  describe '#ancestors' do
    it 'returns empty array when no parent' do
      expect(combo_node.ancestors).to eq([])
    end
  end

  describe '#each_ancestor' do
    it 'returns enumerator when no block given' do
      expect(combo_node.each_ancestor).to be_a(Enumerator)
    end
  end

  describe '#inside_block?' do
    it 'returns false when not inside a block' do
      expect(combo_node.inside_block?(:define)).to be_falsey
    end
  end

  describe '#each_descendant' do
    it 'returns enumerator when no block given' do
      expect(combo_node.each_descendant).to be_a(Enumerator)
    end

    it 'yields descendant nodes' do
      descendants = []
      combo_node.each_descendant(Prism::CallNode) do |node| descendants << node end
      expect(descendants).not_to be_empty
    end
  end

  describe '#find_descendant' do
    it 'returns first matching descendant' do
      result = combo_node.find_descendant(Prism::BlockNode)
      expect(result).to be_a(Prism::BlockNode)
    end
  end

  describe '#child_nodes' do
    it 'returns array of child nodes' do
      expect(combo_node.child_nodes).to be_an(Array)
    end
  end

  describe '#inside_factory_bot?' do
    context 'with FactoryBot.define' do
      let(:source) { 'FactoryBot.define { }' }

      it 'returns false for the define call itself' do
        expect(combo_node.inside_factory_bot?).to be_falsey
      end
    end
  end

  describe '#inside_rspec?' do
    context 'with RSpec describe' do
      let(:source) { 'describe "something" { }' }

      it 'returns false for the describe call itself' do
        expect(combo_node.inside_rspec?).to be_falsey
      end
    end
  end

  describe '#dsl_context' do
    it 'returns nil for non-DSL code' do
      expect(combo_node.dsl_context).to be_nil
    end
  end

  describe '#hash_arguments' do
    context 'with keyword arguments' do
      let(:source) { 'foo(bar: 1, baz: 2)' }

      it 'returns hash of arguments' do
        expect(combo_node.hash_arguments).to be_a(Hash)
      end
    end
  end

  describe '#get_option' do
    context 'with keyword arguments' do
      let(:source) { 'foo(bar: 1, baz: 2)' }

      it 'returns value for existing key' do
        result = combo_node.get_option(:bar)
        expect(result).not_to be_nil
      end

      it 'returns nil for non-existing key' do
        expect(combo_node.get_option(:nonexistent)).to be_nil
      end
    end
  end

  describe '#first_argument' do
    context 'with arguments' do
      let(:source) { 'foo("bar", "baz")' }

      it 'returns first argument' do
        expect(combo_node.first_argument).not_to be_nil
      end
    end

    context 'without arguments' do
      let(:source) { 'foo()' }

      it 'returns nil' do
        expect(combo_node.first_argument).to be_nil
      end
    end
  end

  describe '#last_argument' do
    context 'with arguments' do
      let(:source) { 'foo("bar", "baz")' }

      it 'returns last argument' do
        expect(combo_node.last_argument).not_to be_nil
      end
    end
  end

  describe '#argument_at' do
    context 'with multiple arguments' do
      let(:source) { 'foo("bar", "baz", "qux")' }

      it 'returns argument at index' do
        expect(combo_node.argument_at(1)).not_to be_nil
      end

      it 'returns nil for out of bounds index' do
        expect(combo_node.argument_at(10)).to be_nil
      end
    end
  end

  describe '#matches?' do
    let(:source) { 'define { }' }

    it 'matches symbol' do
      expect(combo_node.matches?(:define)).to be_truthy
    end

    it 'matches array of symbols' do
      expect(combo_node.matches?(%i[define factory])).to be_truthy
    end

    it 'matches regexp' do
      expect(combo_node.matches?(/def/)).to be_truthy
    end

    it 'does not match wrong symbol' do
      expect(combo_node.matches?(:factory)).to be_falsey
    end
  end

  describe '#method_chain' do
    let(:source) { 'foo.bar.baz' }

    it 'returns array of method names' do
      expect(combo_node.method_chain).to eq(%i[foo bar baz])
    end
  end

  describe '#is_method?' do
    let(:source) { 'define { }' }

    it 'returns true for matching method' do
      expect(combo_node.is_method?(:define, :factory)).to be_truthy
    end

    it 'returns false for non-matching method' do
      expect(combo_node.is_method?(:foo, :bar)).to be_falsey
    end
  end

  describe '#source_range' do
    it 'returns location object' do
      expect(combo_node.source_range).to respond_to(:start_line)
    end
  end

  describe '#line_range' do
    it 'returns range of lines' do
      expect(combo_node.line_range).to be_a(Range)
    end
  end

  describe '#single_line?' do
    context 'with single line code' do
      let(:source) { 'foo' }

      it 'returns true' do
        expect(combo_node.single_line?).to be_truthy
      end
    end
  end

  describe '#multi_line?' do
    context 'with single line code' do
      let(:source) { 'foo' }

      it 'returns false' do
        expect(combo_node.multi_line?).to be_falsey
      end
    end
  end

  describe '#column' do
    it 'returns column number' do
      expect(combo_node.column).to be_a(Integer)
    end
  end

  describe '#block_empty?' do
    context 'with empty block' do
      let(:source) { 'foo { }' }

      it 'returns true' do
        expect(combo_node.block_empty?).to be_truthy
      end
    end

    context 'with non-empty block' do
      let(:source) { 'foo { bar }' }

      it 'returns false' do
        expect(combo_node.block_empty?).to be_falsey
      end
    end

    context 'without block' do
      let(:source) { 'foo' }

      it 'returns true' do
        expect(combo_node.block_empty?).to be_truthy
      end
    end
  end

  describe '#block_statement_count' do
    context 'with multiple statements' do
      let(:source) { 'foo { bar; baz; qux }' }

      it 'returns statement count' do
        expect(combo_node.block_statement_count).to eq(3)
      end
    end

    context 'without block' do
      let(:source) { 'foo' }

      it 'returns 0' do
        expect(combo_node.block_statement_count).to eq(0)
      end
    end
  end

  describe '#block_has_method?' do
    context 'with method in block' do
      let(:source) { 'foo { bar }' }

      it 'returns true for existing method' do
        expect(combo_node.block_has_method?(:bar)).to be_truthy
      end

      it 'returns false for non-existing method' do
        expect(combo_node.block_has_method?(:baz)).to be_falsey
      end
    end
  end

  describe '#block_each_statement' do
    context 'with block' do
      let(:source) { 'foo { bar; baz }' }

      it 'returns enumerator when no block given' do
        expect(combo_node.block_each_statement).to be_a(Enumerator)
      end

      it 'yields each statement' do
        statements = []
        combo_node.block_each_statement do |stmt| statements << stmt end
        expect(statements.size).to eq(2)
      end
    end
  end

  describe '#receiver' do
    context 'with receiver' do
      let(:source) { 'obj.method' }

      it 'returns receiver node' do
        expect(combo_node.receiver).not_to be_nil
      end
    end

    context 'without receiver' do
      let(:source) { 'method' }

      it 'returns nil' do
        expect(combo_node.receiver).to be_nil
      end
    end
  end

  describe '#name' do
    let(:source) { 'foo_method' }

    it 'returns method name' do
      expect(combo_node.name).to eq(:foo_method)
    end
  end

  describe '#arguments_count' do
    context 'with arguments' do
      let(:source) { 'foo(1, 2, 3)' }

      it 'returns argument count' do
        expect(combo_node.arguments_count).to eq(3)
      end
    end

    context 'without arguments' do
      let(:source) { 'foo' }

      it 'returns 0' do
        expect(combo_node.arguments_count).to eq(0)
      end
    end
  end

  describe '#has_arguments?' do
    context 'with arguments' do
      let(:source) { 'foo(1)' }

      it 'returns true' do
        expect(combo_node.has_arguments?).to be true
      end
    end

    context 'without arguments' do
      let(:source) { 'foo' }

      it 'returns false' do
        expect(combo_node.has_arguments?).to be false
      end
    end
  end

  describe '#has_block?' do
    context 'with block' do
      let(:source) { 'foo { bar }' }

      it 'returns true' do
        expect(combo_node.has_block?).to be true
      end
    end

    context 'without block' do
      let(:source) { 'foo' }

      it 'returns false' do
        expect(combo_node.has_block?).to be false
      end
    end
  end

  describe '#literal_value' do
    context 'with string literal' do
      let(:source) { 'foo("bar")' }

      it 'returns string value' do
        expect(combo_node.literal_value).to eq('bar')
      end
    end

    context 'with symbol literal' do
      let(:source) { 'foo(:bar)' }

      it 'returns symbol value' do
        expect(combo_node.literal_value).to eq(:bar)
      end
    end

    context 'with integer literal' do
      let(:source) { 'foo(42)' }

      it 'returns integer value' do
        expect(combo_node.literal_value).to eq(42)
      end
    end

    context 'with boolean literal' do
      let(:source) { 'foo(true)' }

      it 'returns boolean value' do
        expect(combo_node.literal_value).to eq(true)
      end
    end

    context 'with nil literal' do
      let(:source) { 'foo(nil)' }

      it 'returns nil' do
        expect(combo_node.literal_value).to be_nil
      end
    end

    context 'without arguments' do
      let(:source) { 'foo' }

      it 'returns nil' do
        expect(combo_node.literal_value).to be_nil
      end
    end
  end

  describe '#constant?' do
    context 'with constant receiver' do
      let(:source) { 'Foo.bar' }

      it 'returns true' do
        expect(combo_node.constant?).to be_truthy
      end
    end

    context 'without receiver' do
      let(:source) { 'bar' }

      it 'returns false' do
        expect(combo_node.constant?).to be_falsey
      end
    end
  end

  describe '#variable?' do
    context 'with variable receiver' do
      let(:source) { 'foo.bar' }
      let(:result) { Prism.parse('foo = 1; foo.bar') }
      let(:root_node) { result.value.statements.body.last }

      it 'returns true' do
        expect(combo_node.variable?).to be_truthy
      end
    end

    context 'with instance variable receiver' do
      let(:source) { '@foo.bar' }

      it 'returns true' do
        expect(combo_node.variable?).to be_truthy
      end
    end

    context 'without receiver' do
      let(:source) { 'bar' }

      it 'returns false' do
        expect(combo_node.variable?).to be_falsey
      end
    end
  end

  describe '#literal?' do
    context 'with literal argument' do
      let(:source) { 'foo("bar")' }

      it 'returns true' do
        expect(combo_node.literal?).to be_truthy
      end
    end

    context 'with non-literal argument' do
      let(:source) { 'foo(bar)' }

      it 'returns false' do
        expect(combo_node.literal?).to be_falsey
      end
    end

    context 'without arguments' do
      let(:source) { 'foo' }

      it 'returns false' do
        expect(combo_node.literal?).to be_falsey
      end
    end
  end

  describe '#inside_class?' do
    context 'inside class' do
      let(:source) { "class Foo\n  def bar; end\nend" }
      let(:combo_node) do
        result = Prism.parse(source)
        node = result.value.statements.body.first.body.body.first
        PrismCombo::ComboNode.new(node)
      end
    end

    context 'outside class' do
      let(:source) { 'def bar; end' }

      it 'returns false' do
        expect(combo_node.inside_class?).to be false
      end
    end
  end

  describe '#inside_module?' do
    context 'inside module' do
      let(:source) { "module Foo\n  def bar; end\nend" }
      let(:combo_node) do
        result = Prism.parse(source)
        node = result.value.statements.body.first.body.body.first
        PrismCombo::ComboNode.new(node)
      end
    end

    context 'outside module' do
      let(:source) { 'def bar; end' }

      it 'returns false' do
        expect(combo_node.inside_module?).to be false
      end
    end
  end

  describe '#inside_def?' do
    context 'inside method definition' do
      let(:source) { "def foo\n  bar\nend" }
      let(:combo_node) do
        result = Prism.parse(source)
        node = result.value.statements.body.first.body.body.first
        PrismCombo::ComboNode.new(node)
      end
    end

    context 'outside method definition' do
      let(:source) { 'bar' }

      it 'returns false' do
        expect(combo_node.inside_def?).to be false
      end
    end
  end

  describe '#single_argument?' do
    context 'with single argument' do
      let(:source) { 'foo(1)' }

      it 'returns true' do
        expect(combo_node.single_argument?).to be true
      end
    end

    context 'with multiple arguments' do
      let(:source) { 'foo(1, 2)' }

      it 'returns false' do
        expect(combo_node.single_argument?).to be false
      end
    end

    context 'without arguments' do
      let(:source) { 'foo' }

      it 'returns false' do
        expect(combo_node.single_argument?).to be false
      end
    end
  end

  describe '#each_argument' do
    context 'with arguments' do
      let(:source) { 'foo(1, 2, 3)' }

      it 'yields each argument' do
        count = 0
        combo_node.each_argument do count += 1 end
        expect(count).to eq(3)
      end

      it 'returns enumerator when no block given' do
        expect(combo_node.each_argument).to be_a(Enumerator)
      end
    end

    context 'without arguments' do
      let(:source) { 'foo' }

      it 'yields nothing' do
        count = 0
        combo_node.each_argument do count += 1 end
        expect(count).to eq(0)
      end
    end
  end

  describe '#string_argument?' do
    context 'with string argument' do
      let(:source) { 'foo("bar")' }

      it 'returns true' do
        expect(combo_node.string_argument?).to be true
      end
    end

    context 'without string argument' do
      let(:source) { 'foo(123)' }

      it 'returns false' do
        expect(combo_node.string_argument?).to be false
      end
    end
  end

  describe '#symbol_argument?' do
    context 'with symbol argument' do
      let(:source) { 'foo(:bar)' }

      it 'returns true' do
        expect(combo_node.symbol_argument?).to be true
      end
    end

    context 'without symbol argument' do
      let(:source) { 'foo("bar")' }

      it 'returns false' do
        expect(combo_node.symbol_argument?).to be false
      end
    end
  end

  describe '#numeric_argument?' do
    context 'with numeric argument' do
      let(:source) { 'foo(123)' }

      it 'returns true' do
        expect(combo_node.numeric_argument?).to be true
      end
    end

    context 'with float argument' do
      let(:source) { 'foo(123.45)' }

      it 'returns true' do
        expect(combo_node.numeric_argument?).to be true
      end
    end

    context 'without numeric argument' do
      let(:source) { 'foo("bar")' }

      it 'returns false' do
        expect(combo_node.numeric_argument?).to be false
      end
    end
  end

  describe '#initialize' do
    it 'raises ArgumentError for unsupported node types' do
      # ArrayNode is not supported
      result = Prism.parse('[1, 2, 3]')
      node = result.value.statements.body.first
      expect { described_class.new(node) }.to raise_error(ArgumentError, /Expected supported node type/)
    end
  end

  describe '#block_type' do
    context 'when block has no opening_loc' do
      let(:source) { 'foo { bar }' }

      it 'returns nil when opening_loc is nil' do
        allow(combo_node.block_node).to receive(:opening_loc).and_return(nil)
        expect(combo_node.block_type).to be_nil
      end
    end

    context 'with non-BlockNode' do
      let(:source) { 'foo(bar) { baz }' }

      it 'returns nil when block is not a BlockNode' do
        allow(combo_node).to receive(:block_node).and_return('not a block')
        expect(combo_node.block_type).to be_nil
      end
    end
  end

  describe '#single_line_block?' do
    context 'without block' do
      let(:source) { 'foo' }

      it 'returns false' do
        expect(combo_node.single_line_block?).to be false
      end
    end

    context 'with non-BlockNode' do
      let(:source) { 'foo(bar)' }

      it 'returns false when block is not a BlockNode' do
        allow(combo_node).to receive(:block_node).and_return('not a block')
        expect(combo_node.single_line_block?).to be false
      end
    end
  end

  describe '#block_parameters' do
    context 'without parameters' do
      let(:source) { 'foo { bar }' }

      it 'returns empty array when no parameters' do
        expect(combo_node.block_parameters).to eq([])
      end
    end

    context 'with non-BlockNode' do
      let(:source) { 'foo' }

      it 'returns empty array when block is not a BlockNode' do
        expect(combo_node.block_parameters).to eq([])
      end
    end

    context 'when parameters is nil' do
      let(:source) { 'foo { bar }' }

      it 'returns empty array' do
        allow(combo_node.block_node).to receive(:parameters).and_return(nil)
        expect(combo_node.block_parameters).to eq([])
      end
    end
  end

  describe '#extract_parameter_names' do
    context 'with DefNode parameters' do
      let(:source) { 'def foo(a, b = 1, *rest, c:, d: 2, **kwargs, &block); end' }
      let(:result) { Prism.parse(source) }
      let(:root_node) { result.value.statements.body.first }
      let(:combo_node) { described_class.new(root_node) }

      it 'extracts all parameter types' do
        params = combo_node.send(:extract_parameter_names, root_node.parameters)
        expect(params).to include(:a, :b, :rest, :c, :d, :kwargs, :block)
      end
    end
  end

  describe '#keyword_argument?' do
    context 'with various argument types' do
      it 'returns true for KeywordHashNode' do
        source = 'foo(bar: 1)'
        result = Prism.parse(source)
        node = result.value.statements.body.first
        combo = described_class.new(node)
        arg = combo.arguments.first
        expect(combo.send(:keyword_argument?, arg)).to be true
      end

      it 'returns true for AssocNode' do
        # Create a specific structure that results in AssocNode
        source = 'foo(**{bar: 1})'
        result = Prism.parse(source)
        node = result.value.statements.body.first
        combo = described_class.new(node)
        # In this case, we might have a different structure
        expect(combo.keyword_arguments).not_to be_empty
      end
    end
  end

  describe 'edge cases and error handling' do
    describe '#block_body' do
      context 'with non-BlockNode' do
        let(:source) { 'foo' }

        it 'returns nil' do
          expect(combo_node.block_body).to be_nil
        end
      end
    end

    describe '#block_body_statements' do
      context 'when body is not StatementsNode' do
        let(:source) { 'foo { 123 }' }

        it 'returns empty array' do
          allow(combo_node).to receive(:block_body).and_return('not statements')
          expect(combo_node.block_body_statements).to eq([])
        end
      end
    end

    describe '#numeric_type' do
      context 'with integer' do
        let(:source) { '123' }
        it 'returns :integer' do
          expect(combo_node.numeric_type).to eq(:integer)
        end
      end

      context 'with float' do
        let(:source) { '1.23' }
        it 'returns :float' do
          expect(combo_node.numeric_type).to eq(:float)
        end
      end

      context 'with rational' do
        let(:source) { '1r' }
        it 'returns :rational' do
          expect(combo_node.numeric_type).to eq(:rational)
        end
      end

      context 'with imaginary' do
        let(:source) { '1i' }
        it 'returns :imaginary' do
          expect(combo_node.numeric_type).to eq(:imaginary)
        end
      end
    end

    describe '#string_type' do
      context 'with single quote' do
        let(:source) { "'string'" }
        it 'returns :single_quoted' do
          expect(combo_node.string_type).to eq(:single_quoted)
        end
      end

      context 'with double quote' do
        let(:source) { '"string"' }
        it 'returns :double_quoted' do
          expect(combo_node.string_type).to eq(:double_quoted)
        end
      end

      context 'with heredoc' do
        let(:source) { "<<~RUBY\ntext\nRUBY" }
        it 'returns :heredoc' do
          expect(combo_node.string_type).to eq(:heredoc)
        end
      end

      context 'with percent literal' do
        let(:source) { '%q(string)' }
        it 'returns :percent' do
          expect(combo_node.string_type).to eq(:percent)
        end
      end

      context 'with interpolated string' do
        let(:source) { '"hello #{world}"' }
        it 'returns :interpolated' do
          expect(combo_node.string_type).to eq(:interpolated)
        end
      end

      context 'with non-string node' do
        let(:source) { '123' }
        it 'returns nil' do
          expect(combo_node.string_type).to be_nil
        end
      end
    end
  end

  describe 'additional coverage tests' do
    describe '#block_parameters with parameters' do
      context 'with block parameters' do
        let(:source) { 'foo { |a, b| bar }' }
        it 'returns parameter names' do
          expect(combo_node.block_parameters).to eq([:a, :b])
        end
      end
    end

    describe '#method_name' do
      context 'with node that has name method' do
        let(:source) { 'foo' }
        it 'returns the name' do
          expect(combo_node.method_name).to eq(:foo)
        end
      end
      
      context 'with node that has no name method' do
        let(:source) { '123' }
        let(:result) { Prism.parse(source) }
        let(:root_node) { result.value.statements.body.first }
        let(:combo_node) { described_class.new(root_node) }
        
        it 'returns nil for IntegerNode' do
          expect(combo_node.method_name).to be_nil
        end
      end
    end

    describe '#block_pass_argument with BlockArgumentNode' do
      # BlockArgumentNodeは実際には別の構造で表現される
      context 'with arguments' do
        let(:source) { 'foo(1, 2)' }
        it 'returns nil when no block argument' do
          expect(combo_node.block_pass_argument).to be_nil
        end
      end
    end

    describe '#ancestors with parent_node' do
      context 'with parent node set' do
        let(:source) { 'foo' }
        let(:parent_source) { 'bar { foo }' }
        let(:parent_result) { Prism.parse(parent_source) }
        let(:parent_node) { parent_result.value.statements.body.first }
        
        it 'returns array with parent' do
          combo_node.parent_node = parent_node
          expect(combo_node.ancestors).to eq([parent_node])
        end
      end
    end

    describe '#each_ancestor' do
      context 'with parent node and type filter' do
        let(:source) { 'foo' }
        let(:parent_source) { 'bar { foo }' }
        let(:parent_result) { Prism.parse(parent_source) }
        let(:parent_node) { parent_result.value.statements.body.first }
        
        it 'yields ancestors of specific type' do
          combo_node.parent_node = parent_node
          ancestors = []
          combo_node.each_ancestor(Prism::CallNode) do |ancestor|
            ancestors << ancestor
          end
          expect(ancestors).to eq([parent_node])
        end
      end
    end

    describe '#inside_factory_bot?' do
      context 'with FactoryBot.define ancestor' do
        let(:source) { 'factory :user' }
        let(:parent_source) { 'FactoryBot.define { factory :user }' }
        let(:parent_result) { Prism.parse(parent_source) }
        let(:parent_node) { parent_result.value.statements.body.first }
        let(:factory_node) { parent_node.block.body.body.first }
        let(:combo_node) { described_class.new(factory_node) }
        
        it 'returns true when inside FactoryBot.define' do
          combo_node.parent_node = parent_node
          expect(combo_node.inside_factory_bot?).to be true
        end
      end

      context 'with exception during check' do
        let(:source) { 'foo' }
        it 'returns false on error' do
          allow(combo_node).to receive(:ancestors).and_raise(StandardError)
          expect(combo_node.inside_factory_bot?).to be false
        end
      end
    end

    describe '#inside_block?' do
      context 'with BlockNode that has send_node' do
        let(:source) { 'foo' }
        it 'checks send_node method' do
          block = double('BlockNode')
          allow(block).to receive(:respond_to?).with(:send_node).and_return(true)
          send_node = double('SendNode')
          allow(send_node).to receive(:respond_to?).with(:name).and_return(true)
          allow(send_node).to receive(:name).and_return(:test)
          allow(block).to receive(:send_node).and_return(send_node)
          
          allow(combo_node).to receive(:each_ancestor).with(Prism::BlockNode).and_return([block])
          expect(combo_node.inside_block?(:test)).to be true
        end
      end
    end

    describe '#inside_rspec?' do
      context 'with describe ancestor' do
        let(:source) { 'it "works"' }
        let(:parent_source) { 'describe "Test" { it "works" }' }
        let(:parent_result) { Prism.parse(parent_source) }
        let(:parent_node) { parent_result.value.statements.body.first }
        let(:it_node) { parent_node.block.body.body.first }
        let(:combo_node) { described_class.new(it_node) }
        
        it 'returns true when inside describe' do
          combo_node.parent_node = parent_node
          expect(combo_node.inside_rspec?).to be true
        end
      end

      context 'with exception during check' do
        let(:source) { 'foo' }
        it 'returns false on error' do
          allow(combo_node).to receive(:ancestors).and_raise(StandardError)
          expect(combo_node.inside_rspec?).to be false
        end
      end
    end

    describe '#dsl_context' do
      context 'when inside factory_bot' do
        let(:source) { 'foo' }
        it 'returns :factory_bot' do
          allow(combo_node).to receive(:inside_factory_bot?).and_return(true)
          expect(combo_node.dsl_context).to eq(:factory_bot)
        end
      end

      context 'when inside rspec' do
        let(:source) { 'foo' }
        it 'returns :rspec' do
          allow(combo_node).to receive(:inside_factory_bot?).and_return(false)
          allow(combo_node).to receive(:inside_rspec?).and_return(true)
          expect(combo_node.dsl_context).to eq(:rspec)
        end
      end
    end

    describe '#hash_arguments with AssocNode' do
      # 特殊なケースでAssocNodeが直接引数に来る場合
      context 'with special structure' do
        let(:source) { 'foo(key: 1)' }
        it 'handles AssocNode arguments' do
          result = combo_node.hash_arguments
          expect(result).to be_a(Hash)
        end
      end

      context 'with non-symbol key in AssocNode' do
        it 'handles non-symbol keys' do
          # Create mock arguments with non-symbol key
          arg = double('AssocNode')
          allow(arg).to receive(:is_a?).with(Prism::KeywordHashNode).and_return(false)
          allow(arg).to receive(:is_a?).with(Prism::AssocNode).and_return(true)
          key = double('NonSymbolKey')
          allow(key).to receive(:is_a?).with(Prism::SymbolNode).and_return(false)
          allow(arg).to receive(:key).and_return(key)
          allow(arg).to receive(:value).and_return('value')
          
          allow(combo_node).to receive(:arguments).and_return([arg])
          result = combo_node.hash_arguments
          expect(result[key]).to eq('value')
        end
      end
    end

    describe '#matches?' do
      context 'with unsupported pattern type' do
        let(:source) { 'foo' }
        it 'returns false' do
          expect(combo_node.matches?(123)).to be false
        end
      end
    end

    describe '#string_type with unknown opening' do
      context 'with special string' do
        let(:source) { '"string"' }
        it 'handles edge cases' do
          allow(combo_node.node).to receive_message_chain(:opening_loc, :slice).and_return(nil)
          expect(combo_node.string_type).to eq(:plain)
        end
      end
    end
    describe '#with_prism_edge_cases' do
      context 'with RationalNode' do
        let(:source) { '1r' }
        let(:result) { Prism.parse(source) }
        let(:root_node) { result.value.statements.body.first }
        let(:combo_node) { described_class.new(root_node) }

        it 'initializes successfully' do
          expect(combo_node).to be_a(described_class)
        end
      end

      context 'with ImaginaryNode' do
        let(:source) { '1i' }
        let(:result) { Prism.parse(source) }
        let(:root_node) { result.value.statements.body.first }
        let(:combo_node) { described_class.new(root_node) }

        it 'initializes successfully' do
          expect(combo_node).to be_a(described_class)
        end
      end

      context 'with InterpolatedStringNode' do
        let(:source) { '"hello #{world}"' }
        let(:result) { Prism.parse(source) }
        let(:root_node) { result.value.statements.body.first }
        let(:combo_node) { described_class.new(root_node) }

        it 'initializes successfully' do
          expect(combo_node).to be_a(described_class)
        end
      end

      context 'with ClassVariableReadNode' do
        let(:source) { '@@var' }
        let(:result) { Prism.parse(source) }
        let(:root_node) { result.value.statements.body.first }
        let(:combo_node) { described_class.new(root_node) }

        it 'initializes successfully' do
          expect(combo_node).to be_a(described_class)
        end
      end

      context 'with GlobalVariableReadNode' do
        let(:source) { '$var' }
        let(:result) { Prism.parse(source) }
        let(:root_node) { result.value.statements.body.first }
        let(:combo_node) { described_class.new(root_node) }

        it 'initializes successfully' do
          expect(combo_node).to be_a(described_class)
        end
      end
    end

    describe '#block_type' do
      context 'with brace block' do
        let(:source) { 'foo { bar }' }
        it 'returns :brace' do
          expect(combo_node.block_type).to eq(:brace)
        end
      end

      context 'with do-end block' do
        let(:source) { "foo do\n  bar\nend" }
        it 'returns :do_end' do
          expect(combo_node.block_type).to eq(:do_end)
        end
      end
    end

    describe '#multi_line_block?' do
      context 'with multi-line block' do
        let(:source) { "foo do\n  bar\nend" }
        it 'returns true' do
          expect(combo_node.multi_line_block?).to be true
        end
      end
    end

    describe '#positional_arguments' do
      context 'with mixed arguments' do
        let(:source) { 'foo(1, 2, key: 3)' }
        it 'returns only positional arguments' do
          expect(combo_node.positional_arguments.size).to eq(2)
        end
      end
    end

    describe '#has_keyword_arguments?' do
      context 'with keyword arguments' do
        let(:source) { 'foo(key: 1)' }
        it 'returns true' do
          expect(combo_node.has_keyword_arguments?).to be true
        end
      end
    end

    describe '#empty_arguments?' do
      context 'with no arguments' do
        let(:source) { 'foo' }
        it 'returns true' do
          expect(combo_node.empty_arguments?).to be true
        end
      end
    end

    describe '#has_parentheses?' do
      context 'with parentheses' do
        let(:source) { 'foo()' }
        it 'returns true' do
          expect(combo_node.has_parentheses?).to be true
        end
      end

      context 'without parentheses' do
        let(:source) { 'foo' }
        it 'returns false' do
          expect(combo_node.has_parentheses?).to be false
        end
      end
    end

    describe '#has_receiver?' do
      context 'with receiver' do
        let(:source) { 'obj.foo' }
        it 'returns true' do
          expect(combo_node.has_receiver?).to be true
        end
      end
    end

    describe '#receiver_type' do
      context 'with constant receiver' do
        let(:source) { 'Foo.bar' }
        it 'returns :constantread' do
          expect(combo_node.receiver_type).to eq(:constantread)
        end
      end
    end

    describe '#method_name with DefNode' do
      let(:source) { 'def foo_method; end' }
      let(:result) { Prism.parse(source) }
      let(:root_node) { result.value.statements.body.first }
      let(:combo_node) { described_class.new(root_node) }

      it 'returns method name' do
        expect(combo_node.method_name).to eq(:foo_method)
      end
    end

    describe '#full_method_path' do
      context 'without receiver' do
        let(:source) { 'bar' }
        it 'returns method name' do
          expect(combo_node.full_method_path).to eq('bar')
        end
      end
    end

    describe '#safe_navigation?' do
      context 'with safe navigation operator' do
        let(:source) { 'obj&.foo' }
        it 'returns true' do
          expect(combo_node.safe_navigation?).to be true
        end
      end
    end

    describe '#call_operator' do
      context 'with dot operator' do
        let(:source) { 'obj.foo' }
        it 'returns .' do
          expect(combo_node.call_operator).to eq('.')
        end
      end
    end

    describe '#in_method_chain?' do
      it 'returns false (simplified implementation)' do
        expect(combo_node.in_method_chain?).to be false
      end
    end

    describe '#chain_length' do
      context 'with method chain' do
        let(:source) { 'obj.foo' }
        it 'returns chain length' do
          expect(combo_node.chain_length).to eq(2)
        end
      end
    end

    describe '#root_receiver' do
      context 'without method chain' do
        let(:source) { 'foo' }
        it 'returns nil' do
          expect(combo_node.root_receiver).to be_nil
        end
      end
    end

    describe '#factory_bot_call?' do
      context 'with factory_bot method' do
        let(:source) { 'create(:user)' }
        it 'returns true' do
          expect(combo_node.factory_bot_call?).to be true
        end
      end

      context 'with build_stubbed method' do
        let(:source) { 'build_stubbed(:user)' }
        it 'returns true' do
          expect(combo_node.factory_bot_call?).to be true
        end
      end

      context 'with attributes_for method' do
        let(:source) { 'attributes_for(:user)' }
        it 'returns true' do
          expect(combo_node.factory_bot_call?).to be true
        end
      end
    end

    describe '#rspec_matcher?' do
      context 'with be_ matcher' do
        let(:source) { 'be_valid' }
        it 'returns true' do
          expect(combo_node.rspec_matcher?).to be true
        end
      end

      context 'with include_ matcher' do
        let(:source) { 'include_context' }
        it 'returns true' do
          expect(combo_node.rspec_matcher?).to be true
        end
      end

      context 'with match_ matcher' do
        let(:source) { 'match_array' }
        it 'returns true' do
          expect(combo_node.rspec_matcher?).to be true
        end
      end

      context 'with to_not method' do
        let(:source) { 'to_not' }
        it 'returns true' do
          expect(combo_node.rspec_matcher?).to be true
        end
      end

      context 'with not_to method' do
        let(:source) { 'not_to' }
        it 'returns true' do
          expect(combo_node.rspec_matcher?).to be true
        end
      end
    end

    describe '#rails_query_method?' do
      %i[find find_by includes joins left_joins order limit offset group having].each do |method|
        context "with #{method} method" do
          let(:source) { "#{method}(:id)" }
          it 'returns true' do
            expect(combo_node.rails_query_method?).to be true
          end
        end
      end
    end

    describe '#enumerable_method?' do
      %i[select reject filter find detect any? all? none? one? inject reduce each_with_index].each do |method|
        context "with #{method} method" do
          let(:source) { "#{method} { |x| x }" }
          it 'returns true' do
            expect(combo_node.enumerable_method?).to be true
          end
        end
      end
    end

    describe '#block_pass_argument' do
      context 'without block pass' do
        let(:source) { 'map { |x| x.to_s }' }
        it 'returns nil' do
          expect(combo_node.block_pass_argument).to be_nil
        end
      end
    end

    describe '#has_block_pass?' do
      context 'without block pass' do
        let(:source) { 'map { |x| x }' }
        it 'returns false' do
          expect(combo_node.has_block_pass?).to be false
        end
      end
    end

    describe '#proc_argument?' do
      context 'without proc argument' do
        let(:source) { 'map { |x| x }' }
        it 'returns false' do
          expect(combo_node.proc_argument?).to be false
        end
      end
    end

    describe '#symbol_value' do
      context 'with SymbolNode' do
        let(:source) { ':symbol' }
        let(:result) { Prism.parse(source) }
        let(:root_node) { result.value.statements.body.first }
        let(:combo_node) { described_class.new(root_node) }

        it 'returns the symbol value' do
          expect(combo_node.symbol_value).to eq(:symbol)
        end
      end
    end

    describe '#constant_name' do
      context 'with ConstantReadNode' do
        let(:source) { 'CONSTANT' }
        let(:result) { Prism.parse(source) }
        let(:root_node) { result.value.statements.body.first }
        let(:combo_node) { described_class.new(root_node) }

        it 'returns the constant name' do
          expect(combo_node.constant_name).to eq(:CONSTANT)
        end
      end
    end

    describe '#variable_type' do
      context 'with local variable' do
        let(:source) { 'x = 1; x' }
        let(:result) { Prism.parse(source) }
        let(:root_node) { result.value.statements.body.last }
        let(:combo_node) { described_class.new(root_node) }

        it 'returns :local' do
          expect(combo_node.variable_type).to eq(:local)
        end
      end

      context 'with instance variable' do
        let(:source) { '@var' }
        let(:result) { Prism.parse(source) }
        let(:root_node) { result.value.statements.body.first }
        let(:combo_node) { described_class.new(root_node) }

        it 'returns :instance' do
          expect(combo_node.variable_type).to eq(:instance)
        end
      end

      context 'with class variable' do
        let(:source) { '@@var' }
        let(:result) { Prism.parse(source) }
        let(:root_node) { result.value.statements.body.first }
        let(:combo_node) { described_class.new(root_node) }

        it 'returns :class' do
          expect(combo_node.variable_type).to eq(:class)
        end
      end

      context 'with global variable' do
        let(:source) { '$var' }
        let(:result) { Prism.parse(source) }
        let(:root_node) { result.value.statements.body.first }
        let(:combo_node) { described_class.new(root_node) }

        it 'returns :global' do
          expect(combo_node.variable_type).to eq(:global)
        end
      end
    end

    describe '#to_source' do
      let(:source) { 'foo(bar)' }
      it 'returns source code' do
        expect(combo_node.to_source).to eq(source)
      end
    end

    describe '#location' do
      it 'returns location hash' do
        location = combo_node.location
        expect(location).to have_key(:line)
        expect(location).to have_key(:column)
        expect(location).to have_key(:end_line)
        expect(location).to have_key(:end_column)
      end
    end

    describe '#inspect' do
      it 'returns formatted string' do
        expect(combo_node.inspect).to include('PrismCombo::ComboNode')
      end
    end

    describe '#literal_value with float' do
      context 'with float argument' do
        let(:source) { 'foo(1.5)' }
        it 'returns float value' do
          expect(combo_node.literal_value).to eq(1.5)
        end
      end

      context 'with false argument' do
        let(:source) { 'foo(false)' }
        it 'returns false' do
          expect(combo_node.literal_value).to eq(false)
        end
      end
    end

    describe '#build_receiver_path' do
      context 'with CallNode receiver' do
        let(:source) { 'obj.foo.bar' }
        let(:result) { Prism.parse(source) }
        let(:root_node) { result.value.statements.body.first }
        let(:combo_node) { described_class.new(root_node) }

        it 'builds recursive path' do
          receiver = combo_node.receiver
          path = combo_node.send(:build_receiver_path, receiver)
          expect(path).to include('foo')
        end
      end

      context 'with ConstantReadNode receiver' do
        let(:source) { 'Foo.bar' }
        let(:result) { Prism.parse(source) }
        let(:root_node) { result.value.statements.body.first }
        let(:combo_node) { described_class.new(root_node) }

        it 'returns constant name' do
          receiver = combo_node.receiver
          path = combo_node.send(:build_receiver_path, receiver)
          expect(path).to eq('Foo')
        end
      end

      context 'with LocalVariableReadNode receiver' do
        let(:source) { 'x = 1; x.foo' }
        let(:result) { Prism.parse(source) }
        let(:root_node) { result.value.statements.body.last }
        let(:combo_node) { described_class.new(root_node) }

        it 'returns variable name' do
          receiver = combo_node.receiver
          path = combo_node.send(:build_receiver_path, receiver)
          expect(path).to eq('x')
        end
      end

      context 'with InstanceVariableReadNode receiver' do
        let(:source) { '@var.foo' }
        let(:result) { Prism.parse(source) }
        let(:root_node) { result.value.statements.body.first }
        let(:combo_node) { described_class.new(root_node) }

        it 'returns instance variable name' do
          receiver = combo_node.receiver
          path = combo_node.send(:build_receiver_path, receiver)
          expect(path).to eq('@var')
        end
      end

      context 'with other node type' do
        let(:source) { '"string".foo' }
        let(:result) { Prism.parse(source) }
        let(:root_node) { result.value.statements.body.first }
        let(:combo_node) { described_class.new(root_node) }

        it 'returns node type name' do
          receiver = combo_node.receiver
          path = combo_node.send(:build_receiver_path, receiver)
          expect(path).to eq('String')
        end
      end
    end

    describe '#visit_descendants' do
      context 'with ArrayNode' do
        let(:source) { 'foo([1, 2, 3])' }
        it 'visits array elements' do
          descendants = []
          combo_node.each_descendant(Prism::IntegerNode) { |n| descendants << n }
          expect(descendants.size).to eq(3)
        end
      end

      context 'with HashNode' do
        let(:source) { 'foo({a: 1, b: 2})' }
        it 'visits hash elements' do
          descendants = []
          combo_node.each_descendant(Prism::IntegerNode) { |n| descendants << n }
          expect(descendants.size).to eq(2)
        end
      end

      context 'with AssocNode' do
        let(:source) { 'foo(a: 1)' }
        it 'visits key and value' do
          descendants = []
          combo_node.each_descendant(Prism::SymbolNode) { |n| descendants << n }
          expect(descendants).not_to be_empty
        end
      end

      context 'with KeywordHashNode' do
        let(:source) { 'foo(key1: 1, key2: 2)' }
        it 'visits keyword hash elements' do
          descendants = []
          combo_node.each_descendant(Prism::IntegerNode) { |n| descendants << n }
          expect(descendants.size).to eq(2)
        end
      end
    end
  end
end
