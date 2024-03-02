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
        include Sevencop::CopConcerns::Ordered
        include ::Momocop::Helpers::FactoryBotHelper

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
      end
    end
  end
end
