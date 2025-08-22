# frozen_string_literal: true

module PrismCombo
  class ArgumentsInfo
    attr_reader :arguments_node

    def initialize(arguments_node)
      @arguments_node = arguments_node
      return if arguments_node.is_a?(Prism::ArgumentsNode)

      raise ArgumentError, "Expected Prism::ArgumentsNode, got #{arguments_node.class}"
    end

    def arguments
      arguments_node.arguments
    end

    def count
      arguments.size
    end

    def empty?
      count == 0
    end

    def positional_arguments
      arguments.reject { |arg| keyword_argument?(arg) || block_argument?(arg) }
    end

    def positional_count
      positional_arguments.size
    end

    def keyword_arguments
      arguments.select { |arg| keyword_argument?(arg) }
    end

    def keyword_count
      keyword_arguments.size
    end

    def has_keywords?
      keyword_count > 0
    end

    def keyword_names
      keyword_arguments.flat_map { |arg|
        # keyword_arguments only returns KeywordHashNode due to keyword_argument? filter
        arg.elements.map { |assoc| extract_keyword_name(assoc) }
      }.compact
    end

    def block_arguments
      arguments.select { |arg| block_argument?(arg) }
    end

    def has_block_argument?
      block_arguments.any?
    end

    def splat_arguments
      arguments.select { |arg| splat_argument?(arg) }
    end

    def has_splat?
      splat_arguments.any?
    end

    def literal_arguments
      positional_arguments.select { |arg| literal?(arg) }
    end

    def literal_values
      literal_arguments.map { |arg| extract_literal_value(arg) }
    end

    def argument_types
      arguments.map { |arg| argument_type(arg) }
    end

    def each_argument(&block)
      arguments.each(&block)
    end

    def each_positional(&block)
      positional_arguments.each(&block)
    end

    def each_keyword(&block)
      keyword_arguments.each(&block)
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

    def contains_heredoc?
      arguments.any? { |arg| heredoc_argument?(arg) }
    end

    def contains_regex?
      arguments.any? { |arg| regex_argument?(arg) }
    end

    def contains_symbol?
      arguments.any? { |arg| symbol_argument?(arg) }
    end

    def contains_string?
      arguments.any? { |arg| string_argument?(arg) }
    end

    def contains_interpolation?
      arguments.any? { |arg| interpolated_string?(arg) }
    end

    def to_source
      arguments_node.slice
    end

    def location
      {
        line: arguments_node.location.start_line,
        column: arguments_node.location.start_column,
        end_line: arguments_node.location.end_line,
        end_column: arguments_node.location.end_column
      }
    end

    private

    def keyword_argument?(arg)
      arg.is_a?(Prism::KeywordHashNode)
    end

    def block_argument?(arg)
      arg.is_a?(Prism::BlockArgumentNode)
    end

    def splat_argument?(arg)
      arg.is_a?(Prism::SplatNode)
    end

    def literal?(arg)
      case arg
      when Prism::IntegerNode, Prism::FloatNode, Prism::StringNode,
           Prism::SymbolNode, Prism::TrueNode, Prism::FalseNode,
           Prism::NilNode, Prism::RegularExpressionNode
        true
      else
        false
      end
    end

    def extract_literal_value(arg)
      case arg
      when Prism::IntegerNode, Prism::FloatNode
        arg.value
      when Prism::StringNode
        arg.unescaped
      when Prism::SymbolNode
        arg.unescaped.to_sym
      when Prism::TrueNode
        true
      when Prism::FalseNode
        false
      when Prism::NilNode
        nil
      when Prism::RegularExpressionNode
        arg.unescaped
      end
    end

    def extract_keyword_name(assoc)
      return nil unless assoc.is_a?(Prism::AssocNode)

      case assoc.key
      when Prism::SymbolNode
        assoc.key.unescaped.to_sym
      end
    end

    def argument_type(arg)
      case arg
      when Prism::IntegerNode
        :integer
      when Prism::FloatNode
        :float
      when Prism::StringNode
        :string
      when Prism::SymbolNode
        :symbol
      when Prism::TrueNode
        :true
      when Prism::FalseNode
        :false
      when Prism::NilNode
        :nil
      when Prism::RegularExpressionNode
        :regex
      when Prism::ArrayNode
        :array
      when Prism::HashNode
        :hash
      when Prism::KeywordHashNode
        :keyword_hash
      when Prism::CallNode
        :call
      when Prism::LocalVariableReadNode
        :local_variable
      when Prism::InstanceVariableReadNode
        :instance_variable
      when Prism::ConstantReadNode
        :constant
      when Prism::SplatNode
        :splat
      else
        :unknown
      end
    end

    def heredoc_argument?(arg)
      arg.is_a?(Prism::StringNode) && arg.opening_loc&.slice&.include?('<<')
    end

    def regex_argument?(arg)
      arg.is_a?(Prism::RegularExpressionNode)
    end

    def symbol_argument?(arg)
      arg.is_a?(Prism::SymbolNode)
    end

    def string_argument?(arg)
      arg.is_a?(Prism::StringNode)
    end

    def interpolated_string?(arg)
      arg.is_a?(Prism::InterpolatedStringNode)
    end
  end
end
