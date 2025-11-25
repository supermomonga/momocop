# frozen_string_literal: true

module RuboCop
  module Cop
    module Momocop
      # Ensures that Sorbet signature declarations are accompanied by `extend T::Sig`.
      #
      # sig calls must be block-form invocations that appear immediately above a
      # method definition to be considered.
      #
      # @example
      #   # bad
      #   class User
      #     sig { void }
      #     def call; end
      #   end
      #
      #   # good
      #   class User
      #     extend T::Sig
      #
      #     sig { void }
      #     def call; end
      #   end
      class RbiMissingExtendTSig < RuboCop::Cop::Base
        extend AutoCorrector
        include RangeHelp

        MSG = 'Add `extend T::Sig` when using `sig` to type methods.'

        def_node_matcher :extend_t_sig_call?, <<~PATTERN
          (send nil? :extend <(const (const nil? :T) :Sig) ...>)
        PATTERN

        def_node_matcher :sig_block_call?, <<~PATTERN
          (block (send nil? :sig ...) ...)
        PATTERN

        def on_class(node)
          check_node(node, body_nodes(node), node.loc.keyword)
        end

        def on_module(node)
          check_node(node, body_nodes(node), node.loc.keyword)
        end

        def on_sclass(node)
          check_node(node, body_nodes(node), node.loc.keyword)
        end

        def on_new_investigation
          return unless processed_source.ast

          top_level_nodes = top_level_body_nodes(processed_source.ast)
          check_node(nil, top_level_nodes, top_level_offense_location(top_level_nodes))
        end

        private def check_node(node, nodes, offense_location)
          sig_node = sig_before_method_definition(nodes)
          return unless sig_node
          return if extend_t_sig?(nodes)

          add_offense(offense_location || sig_location(sig_node)) do |corrector|
            autocorrect(corrector, nodes)
          end
        end

        private def sig_before_method_definition(nodes)
          nodes.each_cons(2) do |previous, current|
            next unless sig_block_call?(previous)
            next unless method_definition?(current)
            next unless consecutive_lines?(previous, current)

            return previous
          end

          nil
        end

        private def extend_t_sig?(nodes)
          nodes.any? do |child|
            extend_t_sig_call?(child)
          end
        end

        private def body_nodes(node)
          body = node.body
          return [] unless body

          if body.begin_type?
            body.children
          else
            [body]
          end
        end

        private def top_level_body_nodes(ast)
          return [] unless ast

          if ast.begin_type?
            ast.children
          else
            [ast]
          end
        end

        private def top_level_offense_location(_nodes)
          nil
        end

        private def method_definition?(node)
          node.def_type? || node.defs_type?
        end

        private def consecutive_lines?(first_node, second_node)
          first_node.loc.last_line + 1 == second_node.loc.line
        end

        private def sig_location(sig_node)
          sig_node.send_node&.loc&.selector || sig_node.loc.expression
        end

        private def autocorrect(corrector, nodes)
          first_child = nodes.first
          return unless first_child

          indentation = indentation_for(first_child)
          insert_before_line_start(corrector, first_child, "#{indentation}extend T::Sig\n")
        end

        private def insert_before_line_start(corrector, node, text)
          line_start = node.source_range.begin_pos - node.loc.column
          insertion_range = range_between(line_start, line_start)
          corrector.insert_before(insertion_range, text)
        end

        private def indentation_for(first_child)
          ' ' * first_child.loc.column
        end
      end
    end
  end
end
