# frozen_string_literal: true

module Momocop
  module Helpers
    module FactoryBotHelper
      # @type method inside_factory_bot_factory?(RuboCop::AST::Node): bool
      private def inside_factory_bot_factory?(node)
        context = node.each_ancestor(:block).first
        send_node = context.block_type? ? context.send_node : context

        return send_node.method_name == :factory
      end

      # @type method inside_factory_bot_define?(RuboCop::AST::Node): bool
      private def inside_factory_bot_define?(node)
        ancestors = node.each_ancestor(:block).to_a
        ancestors.any? { |ancestor| ancestor.method_name == :define && ancestor.receiver&.const_name == 'FactoryBot' }
      end

      # @type method factory_bot_define?(RuboCop::AST::Node): bool
      private def factory_bot_define?(node)
        node.send_type? && node.method_name == :define && node.receiver&.const_name == 'FactoryBot'
      end

      RUBOCOP_HELPER_METHODS = %i[trait transient before after].freeze

      # @type method definition_node?(RuboCop::AST::Node): bool
      private def definition_node?(node)
        if node.send_type?
          !RUBOCOP_HELPER_METHODS.include?(node.method_name)
        elsif node.block_type? && node.children.first.send_type?
          !RUBOCOP_HELPER_METHODS.include?(node.children.first.method_name)
        end
      end

      # @type method definition_type(RuboCop::AST::Node): (:association | :property | :sequence)
      private def definition_type(node)
        send_node = node.send_type? ? node : node.children.first
        has_association_body =
          send_node
          .block_node
          &.children
          &.last
          # sinble-statement block or multi-statement block
          &.then { _1.send_type? ? [_1] : _1.children }
          &.any? { _1.is_a?(Parser::AST::Node) && _1.send_type? && _1.method_name == :association }
        if %i[association sequence].include? send_node.method_name
          send_node.method_name
        elsif has_association_body
          :association
        else
          :property
        end
      end

      # @type method definition_name(RuboCop::AST::Node): Symbol
      private def definition_name(node)
        send_node = node.send_type? ? node : node.children.first
        if %i[association sequence].include? send_node.method_name
          send_node.arguments.first.value
        else
          send_node.method_name.to_sym
        end
      end

      # @type method defined_properties(RuboCop::AST::Node): Array[RuboCop::AST::Node]
      private def defined_properties(node)
        block_node = node.block_type? ? node : node.block_node
        body_node = block_node&.children&.last

        # empty block
        return [] unless body_node

        # begin
        if body_node.begin_type?
          body_node&.children&.select { |child_node| definition_node?(child_node) } || []
        # block
        elsif body_node.send_type? && definition_node?(body_node)
          [body_node]
        end
      end
    end
  end
end
