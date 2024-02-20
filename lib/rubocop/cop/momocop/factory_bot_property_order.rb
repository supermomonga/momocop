# frozen_string_literal: true

module RuboCop
  module Cop
    module Momocop
      # Ensures that FactoryBot factories has ordered property definitions.
      # 1. Associations should be defined before other properties.
      # 2. Associations and properties should be defined in alphabetical order.
      #
      # @example
      #   # bad
      #   factory :user, class: 'User' do
      #     address { '123 Main St' }
      #     association :profile
      #   end
      #
      #   # good
      #   factory :user, class: 'User' do
      #     association :profile
      #     address { '123 Main St' }
      #   end
      #
      #   # bad
      #   factory :user, class: 'User' do
      #     association :profile
      #     association :account
      #     zipcode { '111-1111' }
      #     address { '123 Main St' }
      #   end
      #
      #   # good
      #   factory :user, class: 'User' do
      #     association :account
      #     association :profile
      #     address { '123 Main St' }
      #     zipcode { '111-1111' }
      #   end
      class FactoryBotPropertyOrder < RuboCop::Cop::Base
        extend AutoCorrector
        include RangeHelp

        include ::Sevencop::CopConcerns::Ordered

        MSG = 'Sort properties and associations alphabetically.'

        RESTRICT_ON_SEND = %i[factory].freeze

        def on_send(node)
          return unless inside_factory_bot_define?(node)

          block_node = node.block_node
          return unless block_node

          entire_definitions = defined_properties(block_node)

          sections =
            entire_definitions
            .slice_when { |a, b|
              (range_with_comments(b).first_line - range_with_comments(a).last_line) > 1
            }
            .select { |definitions| definitions.size >= 2 }

          sections.each do |definitions|
            add_offense(definitions.last) do |corrector|
              (a, b) =
                definitions
                .lazy
                .each_cons(2)
                .find { |a, b| (order(a) <=> order(b)) == 1 }

              break unless a && b

              swap(
                range_with_comments_and_lines(a),
                range_with_comments_and_lines(b),
                corrector:
              )
            end
          end
        end

        private def order(node)
          group = definition_type(node) == :association ? 0 : 1
          index = definition_name(node)
          [group, index]
        end

        private def defined_properties(block_node)
          body_node = block_node&.children&.last

          # empty block
          return [] unless body_node

          # begin
          if body_node.begin_type?
            body_node&.children&.select { |node| definition_node?(node) } || []
          # block
          elsif body_node.send_type? && definition_node?(body_node)
            [body_node]
          else
            []
          end
        end

        RUBOCOP_HELPER_METHODS = %i[trait transient before after].freeze

        private def definition_node?(node)
          if node.send_type?
            return !RUBOCOP_HELPER_METHODS.include?(node.method_name)
          elsif node.block_type? && node.children.first.send_type?
            return !RUBOCOP_HELPER_METHODS.include?(node.children.first.method_name)
          end

          return false
        end

        private def definition_type(node)
          send_node = node.send_type? ? node : node.children.first
          if %i[association sequence].include? send_node.method_name
            send_node.method_name
          else
            :property
          end
        end

        private def definition_name(node)
          send_node = node.send_type? ? node : node.children.first
          if %i[association sequence].include? send_node.method_name
            send_node.arguments.first.value
          else
            send_node.method_name.to_sym
          end
        end

        private def inside_factory_bot_define?(node)
          ancestors = node.each_ancestor(:block).to_a
          ancestors.any? { |ancestor| ancestor.method_name == :define && ancestor.receiver&.const_name == 'FactoryBot' }
        end
      end
    end
  end
end
