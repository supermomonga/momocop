# frozen_string_literal: true

module PrismCombo
  class ComboNode
    attr_reader :node
    attr_accessor :parent_node

    def initialize(node, parent_node = nil)
      @node = node
      @parent_node = parent_node
      # Allow various node types for extended functionality
      return if node.is_a?(Prism::CallNode) || node.is_a?(Prism::DefNode) ||
                node.is_a?(Prism::IntegerNode) || node.is_a?(Prism::FloatNode) ||
                node.is_a?(Prism::RationalNode) || node.is_a?(Prism::ImaginaryNode) ||
                node.is_a?(Prism::StringNode) || node.is_a?(Prism::InterpolatedStringNode) ||
                node.is_a?(Prism::SymbolNode) || node.is_a?(Prism::ConstantReadNode) ||
                node.is_a?(Prism::LocalVariableReadNode) || node.is_a?(Prism::InstanceVariableReadNode) ||
                node.is_a?(Prism::ClassVariableReadNode) || node.is_a?(Prism::GlobalVariableReadNode)

      raise ArgumentError, "Expected supported node type, got #{node.class}"
    end

    # ブロック関連
    def has_block?
      !node.block.nil?
    end

    def block_node
      node.block
    end

    def block_type
      return nil unless has_block?
      return nil unless block_node.is_a?(Prism::BlockNode)

      case block_node.opening_loc&.slice
      when '{'
        :brace
      when 'do'
        :do_end
      end
    end

    def single_line_block?
      return false unless has_block?
      return false unless block_node.is_a?(Prism::BlockNode)

      block_node.opening_loc.start_line == block_node.closing_loc.start_line
    end

    def multi_line_block?
      return false unless has_block?

      !single_line_block?
    end

    def block_parameters
      return [] unless has_block?
      return [] unless block_node.is_a?(Prism::BlockNode)

      params = block_node.parameters&.parameters
      return [] unless params

      extract_parameter_names(params)
    end

    def block_body
      return nil unless has_block?
      return nil unless block_node.is_a?(Prism::BlockNode)

      block_node.body
    end

    def block_body_statements
      return [] unless has_block?

      body = block_body
      return [] unless body.is_a?(Prism::StatementsNode)

      body.body
    end

    # 引数関連
    def has_arguments?
      !node.arguments.nil?
    end

    def arguments
      return [] unless has_arguments?

      node.arguments.arguments
    end

    def argument_count
      arguments.size
    end

    def positional_arguments
      arguments.reject { |arg| keyword_argument?(arg) }
    end

    def keyword_arguments
      arguments.select { |arg| keyword_argument?(arg) }
    end

    def has_keyword_arguments?
      keyword_arguments.any?
    end

    def single_argument?
      argument_count == 1
    end

    def empty_arguments?
      argument_count == 0
    end

    def each_argument(&block)
      return enum_for(:each_argument) unless block_given?

      arguments.each(&block)
    end

    def string_argument?
      return false unless has_arguments?

      arguments.any? { |arg| arg.is_a?(Prism::StringNode) || arg.is_a?(Prism::InterpolatedStringNode) }
    end

    def symbol_argument?
      return false unless has_arguments?

      arguments.any? { |arg| arg.is_a?(Prism::SymbolNode) }
    end

    def numeric_argument?
      return false unless has_arguments?

      arguments.any? { |arg| arg.is_a?(Prism::IntegerNode) || arg.is_a?(Prism::FloatNode) }
    end

    def has_parentheses?
      !node.opening_loc.nil?
    end

    # レシーバー関連
    def has_receiver?
      !node.receiver.nil?
    end

    def receiver
      node.receiver
    end

    def receiver_type
      return nil unless has_receiver?

      receiver.class.name.split('::').last.sub(/Node$/, '').downcase.to_sym
    end

    def method_name
      return node.name if node.respond_to?(:name)
      return node.name_loc.slice.to_sym if node.is_a?(Prism::DefNode)

      nil
    end

    # エイリアスメソッド
    alias arguments_count argument_count
    alias name method_name

    def full_method_path
      return method_name.to_s unless has_receiver?

      receiver_path = build_receiver_path(receiver)
      "#{receiver_path}.#{method_name}"
    end

    # Safe navigation operator
    def safe_navigation?
      node.call_operator_loc&.slice == '&.'
    end

    def call_operator
      node.call_operator_loc&.slice
    end

    # メソッドチェーン
    def in_method_chain?
      parent = find_parent_call_node
      !parent.nil?
    end

    def chain_length
      count = 1
      current = node

      while current.receiver.is_a?(Prism::CallNode)
        count += 1
        current = current.receiver
      end

      count
    end

    def chain_methods
      methods = [method_name]
      current = node

      while current.receiver.is_a?(Prism::CallNode)
        current = current.receiver
        methods.unshift(current.name)
      end

      methods
    end

    def root_receiver
      current = node

      current = current.receiver while current.receiver.is_a?(Prism::CallNode)

      current.receiver
    end

    # 特殊なパターン検出
    def factory_bot_call?
      %i[create build build_stubbed attributes_for].include?(method_name)
    end

    def rspec_matcher?
      %i[to to_not not_to].include?(method_name) ||
        method_name.to_s.start_with?('have_', 'be_', 'include_', 'match_')
    end

    def rails_query_method?
      %i[where find find_by includes joins left_joins order limit offset group having].include?(method_name)
    end

    def enumerable_method?
      %i[each map select reject filter find detect any? all? none? one? inject reduce
         each_with_index].include?(method_name)
    end

    # ブロック引数にProcを渡している場合（&:symbolなど）
    def block_pass_argument
      return nil unless has_arguments?

      arguments.find { |arg| arg.is_a?(Prism::BlockArgumentNode) }
    end

    def has_block_pass?
      !block_pass_argument.nil?
    end

    def proc_argument?
      has_block_pass?
    end

    # 親ノード・階層関連

    def ancestors
      result = []
      current = parent_node
      while current
        result << current
        current = current.respond_to?(:parent_node) ? current.parent_node : nil
      end
      result
    end

    def each_ancestor(type = nil)
      return enum_for(:each_ancestor, type) unless block_given?

      ancestors.each do |ancestor|
        if type.nil? || ancestor.is_a?(type)
          yield ancestor
        end
      end
    end

    def inside_block?(method_name)
      each_ancestor(Prism::BlockNode).any? do |block|
        block.respond_to?(:send_node) &&
          block.send_node.respond_to?(:name) &&
          block.send_node.name == method_name
      end
    end

    def inside_class?
      ancestors.any? { |ancestor| ancestor.is_a?(Prism::ClassNode) }
    end

    def inside_module?
      ancestors.any? { |ancestor| ancestor.is_a?(Prism::ModuleNode) }
    end

    def inside_def?
      ancestors.any? { |ancestor| ancestor.is_a?(Prism::DefNode) }
    end

    # 子ノード探索
    def each_descendant(type = nil, &block)
      return enum_for(:each_descendant, type) unless block_given?

      visit_descendants(node, type, &block)
    end

    def find_descendant(type)
      each_descendant(type).first
    end

    def child_nodes
      children = []
      children << node.receiver if node.receiver
      children << node.arguments if node.arguments
      children << node.block if node.block
      children.compact
    end

    # DSL判定メソッド
    def inside_factory_bot?
      ancestors.any? do |ancestor|
        if ancestor.is_a?(Prism::CallNode)
          combo = ComboNode.new(ancestor)
          combo.method_name == :define &&
            combo.receiver.is_a?(Prism::ConstantReadNode) &&
            combo.receiver.name == :FactoryBot
        end
      end
    rescue StandardError
      false
    end

    def inside_rspec?
      ancestors.any? do |ancestor|
        if ancestor.is_a?(Prism::CallNode)
          combo = ComboNode.new(ancestor)
          %i[describe context it expect].include?(combo.method_name)
        end
      end
    rescue StandardError
      false
    end

    def dsl_context
      return :factory_bot if inside_factory_bot?
      return :rspec if inside_rspec?
      return :rails if rails_query_method?

      nil
    end

    # 引数解析強化
    def hash_arguments
      result = {}
      arguments.each do |arg|
        if arg.is_a?(Prism::KeywordHashNode)
          arg.elements.each do |elem|
            if elem.is_a?(Prism::AssocNode)
              key = elem.key.is_a?(Prism::SymbolNode) ? elem.key.value.to_sym : elem.key
              result[key] = elem.value
            end
          end
        elsif arg.is_a?(Prism::AssocNode)
          key = arg.key.is_a?(Prism::SymbolNode) ? arg.key.value.to_sym : arg.key
          result[key] = arg.value
        end
      end
      result
    end

    def get_option(key)
      hash_arguments[key]
    end

    def first_argument
      arguments.first
    end

    def last_argument
      arguments.last
    end

    def argument_at(index)
      arguments[index]
    end

    # パターンマッチング
    def matches?(pattern)
      case pattern
      when Symbol
        method_name == pattern
      when Array
        pattern.include?(method_name)
      when Regexp
        method_name.to_s.match?(pattern)
      else
        false
      end
    end

    def method_chain
      chain_methods
    end

    def is_method?(*names)
      names.include?(method_name)
    end

    # 位置情報・ソース操作
    def source_range
      node.location
    end

    def line_range
      node.location.start_line..node.location.end_line
    end

    def single_line?
      node.location.start_line == node.location.end_line
    end

    def multi_line?
      !single_line?
    end

    def column
      node.location.start_column
    end

    # ブロック内容解析
    def block_empty?
      return true unless has_block?

      body = block_body
      body.nil? || (body.is_a?(Prism::StatementsNode) && body.body.empty?)
    end

    def block_statement_count
      block_body_statements.size
    end

    def block_has_method?(method_name)
      return false unless has_block?

      each_descendant(Prism::CallNode).any? do |call_node|
        combo = ComboNode.new(call_node)
        combo.method_name == method_name
      end
    end

    def block_each_statement(&block)
      return enum_for(:block_each_statement) unless block_given?

      block_body_statements.each(&block)
    end

    # 型判定ヘルパー
    def literal_value
      return nil unless arguments.any?

      arg = first_argument
      case arg
      when Prism::StringNode
        arg.unescaped
      when Prism::SymbolNode
        arg.unescaped.to_sym
      when Prism::IntegerNode
        arg.value
      when Prism::FloatNode
        arg.value
      when Prism::TrueNode
        true
      when Prism::FalseNode
        false
      when Prism::NilNode
        nil
      end
    end

    def constant?
      receiver.is_a?(Prism::ConstantReadNode)
    end

    def variable?
      receiver.is_a?(Prism::LocalVariableReadNode) ||
        receiver.is_a?(Prism::InstanceVariableReadNode) ||
        receiver.is_a?(Prism::ClassVariableReadNode) ||
        receiver.is_a?(Prism::GlobalVariableReadNode)
    end

    def literal?
      return false unless arguments.any?

      arg = first_argument
      arg.is_a?(Prism::StringNode) ||
        arg.is_a?(Prism::SymbolNode) ||
        arg.is_a?(Prism::IntegerNode) ||
        arg.is_a?(Prism::FloatNode) ||
        arg.is_a?(Prism::TrueNode) ||
        arg.is_a?(Prism::FalseNode) ||
        arg.is_a?(Prism::NilNode)
    end

    # ヘルパーメソッド
    def to_source
      node.slice
    end

    def location
      {
        line: node.location.start_line,
        column: node.location.start_column,
        end_line: node.location.end_line,
        end_column: node.location.end_column
      }
    end

    def inspect
      "#<PrismCombo::ComboNode method=#{method_name} receiver=#{has_receiver?} args=#{argument_count} block=#{has_block?}>"
    end

    # Numeric type detection
    def numeric_type
      case node
      when Prism::IntegerNode
        :integer
      when Prism::FloatNode
        :float
      when Prism::RationalNode
        :rational
      when Prism::ImaginaryNode
        :imaginary
      else
        nil
      end
    end

    # String type detection
    def string_type
      case node
      when Prism::StringNode
        opening = node.opening_loc&.slice
        case opening
        when "'"
          :single_quoted
        when '"'
          :double_quoted
        when /^<</
          :heredoc
        when /^%/
          :percent
        else
          :plain
        end
      when Prism::InterpolatedStringNode
        :interpolated
      else
        nil
      end
    end

    # Symbol value extraction
    def symbol_value
      return node.unescaped.to_sym if node.is_a?(Prism::SymbolNode)
      nil
    end

    # Constant name extraction
    def constant_name
      return node.name if node.is_a?(Prism::ConstantReadNode)
      nil
    end

    # Variable type detection
    def variable_type
      case node
      when Prism::LocalVariableReadNode
        :local
      when Prism::InstanceVariableReadNode
        :instance
      when Prism::ClassVariableReadNode
        :class
      when Prism::GlobalVariableReadNode
        :global
      else
        nil
      end
    end

    private def extract_parameter_names(params)
      names = []

      names += params.requireds.map { |p| p.name.to_sym } if params.requireds
      names += params.optionals.map { |p| p.name.to_sym } if params.optionals
      names << params.rest.name.to_sym if params.rest
      names += params.posts.map { |p| p.name.to_sym } if params.posts
      names += params.keywords.map { |p| p.name.name.to_sym } if params.keywords
      names << params.keyword_rest.name.to_sym if params.keyword_rest
      names << params.block.name.to_sym if params.block

      names
    end

    private def keyword_argument?(arg)
      arg.is_a?(Prism::KeywordHashNode) ||
      (arg.is_a?(Prism::AssocNode) && arg.key.is_a?(Prism::SymbolNode))
    end

    private def build_receiver_path(receiver)
      case receiver
      when Prism::CallNode
        ComboNode.new(receiver).full_method_path
      when Prism::ConstantReadNode
        receiver.name.to_s
      when Prism::LocalVariableReadNode
        receiver.name.to_s
      when Prism::InstanceVariableReadNode
        receiver.name.to_s
      else
        receiver.class.name.split('::').last.sub(/Node$/, '')
      end
    end

    private def find_parent_call_node
      # 実際のRubocopでは親ノードを辿る機能がありますが、
      # ここでは簡略化のためnilを返します
      nil
    end

    private def visit_descendants(node, type = nil, &block)
      return unless node

      # ノード自体を処理
      if (type.nil? || node.is_a?(type)) && (node != @node)
        yield node
      end

      # 子ノードを再帰的に探索
      case node
      when Prism::CallNode
        visit_descendants(node.receiver, type, &block) if node.receiver
        visit_descendants(node.arguments, type, &block) if node.arguments
        visit_descendants(node.block, type, &block) if node.block
      when Prism::ArgumentsNode
        node.arguments.each { |arg| visit_descendants(arg, type, &block) }
      when Prism::BlockNode
        visit_descendants(node.parameters, type, &block) if node.parameters
        visit_descendants(node.body, type, &block) if node.body
      when Prism::StatementsNode
        node.body.each { |stmt| visit_descendants(stmt, type, &block) }
      when Prism::ArrayNode
        node.elements.each { |elem| visit_descendants(elem, type, &block) }
      when Prism::HashNode
        node.elements.each { |elem| visit_descendants(elem, type, &block) }
      when Prism::AssocNode
        visit_descendants(node.key, type, &block)
        visit_descendants(node.value, type, &block)
      when Prism::KeywordHashNode
        node.elements.each { |elem| visit_descendants(elem, type, &block) }
      end
    end
  end
end
