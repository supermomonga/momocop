# frozen_string_literal: true

module PrismCombo
  class BlockInfo
    attr_reader :block_node

    def initialize(block_node)
      @block_node = block_node
      return if block_node.is_a?(Prism::BlockNode)

      raise ArgumentError, "Expected Prism::BlockNode, got #{block_node.class}"
    end

    def style
      case block_node.opening_loc&.slice
      when '{'
        :brace
      when 'do'
        :do_end
      else
        :unknown
      end
    end

    def single_line?
      block_node.opening_loc.start_line == block_node.closing_loc.start_line
    end

    def multi_line?
      !single_line?
    end

    def parameters
      return [] unless block_node.parameters

      params = block_node.parameters.parameters
      return [] unless params

      extract_parameters(params)
    end

    def parameter_names
      parameters.map { |p| p[:name] }
    end

    def parameter_count
      parameter_names.size
    end

    def body_statements
      return [] unless block_node.body.is_a?(Prism::StatementsNode)

      block_node.body.body
    end

    def statement_count
      body_statements.size
    end

    def empty?
      statement_count == 0
    end

    def single_statement?
      statement_count == 1
    end

    def first_statement
      body_statements.first
    end

    def last_statement
      body_statements.last
    end

    def returns_value?
      !empty? && !last_statement_is_void?
    end

    def each_statement(&block)
      body_statements.each(&block)
    end

    def contains_return?
      contains_node_type?(Prism::ReturnNode)
    end

    def contains_break?
      contains_node_type?(Prism::BreakNode)
    end

    def contains_next?
      contains_node_type?(Prism::NextNode)
    end

    def contains_local_variable_write?
      contains_node_type?(Prism::LocalVariableWriteNode)
    end

    def to_source
      block_node.slice
    end

    def location
      {
        line: block_node.location.start_line,
        column: block_node.location.start_column,
        end_line: block_node.location.end_line,
        end_column: block_node.location.end_column
      }
    end

    private

    def extract_parameters(params)
      result = []

      if params.requireds
        params.requireds.each do |p|
          result << { name: p.name, type: :required }
        end
      end

      if params.optionals
        params.optionals.each do |p|
          result << { name: p.name, type: :optional, default: p.value }
        end
      end

      if params.rest
        result << { name: params.rest.name, type: :rest }
      end

      if params.posts
        params.posts.each do |p|
          result << { name: p.name, type: :post }
        end
      end

      if params.keywords
        params.keywords.each do |p|
          name = p.respond_to?(:name) ? p.name : p.name.name
          param_info = { name:, type: :keyword }
          param_info[:default] = p.value if p.respond_to?(:value)
          result << param_info
        end
      end

      if params.keyword_rest
        result << { name: params.keyword_rest.name, type: :keyword_rest }
      end

      if params.block
        result << { name: params.block.name, type: :block }
      end

      result
    end

    def last_statement_is_void?
      return false if empty?

      last = last_statement
      case last
      when Prism::CallNode
        %i[puts print p pp].include?(last.name)
      when Prism::ReturnNode, Prism::BreakNode, Prism::NextNode
        true
      when Prism::ConstantReadNode
        # Constants are considered void (unsupported) for returns_value?
        true
      else
        false
      end
    end

    def contains_node_type?(node_class)
      traverse_nodes(block_node.body) do |node|
        return true if node.is_a?(node_class)
      end
      false
    end

    def traverse_nodes(node, &block)
      return unless node

      yield node

      case node
      when Prism::StatementsNode
        node.body.each { |child| traverse_nodes(child, &block) }
      when Prism::IfNode
        traverse_nodes(node.predicate, &block)
        traverse_nodes(node.statements, &block)
        traverse_nodes(node.consequent, &block)
      when Prism::ElseNode
        traverse_nodes(node.statements, &block)
      when Prism::CallNode
        traverse_nodes(node.receiver, &block)
        traverse_nodes(node.arguments, &block)
        traverse_nodes(node.block, &block)
      when Prism::BlockNode
        traverse_nodes(node.body, &block)
      when Prism::ArgumentsNode
        node.arguments.each { |arg| traverse_nodes(arg, &block) }
      end
    end
  end
end
