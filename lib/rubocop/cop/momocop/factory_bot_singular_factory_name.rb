# frozen_string_literal: true

require 'active_support/core_ext/string/inflections'

module RuboCop
  module Cop
    module Momocop
      # Ensures that FactoryBot factories have singular names.
      #
      # @example
      #   # bad
      #   FactoryBot.define do
      #     factory :users do
      #     end
      #   end
      #
      #   # good
      #   FactoryBot.define do
      #     factory :user do
      #     end
      #   end
      class FactoryBotSingularFactoryName < RuboCop::Cop::Base
        extend AutoCorrector

        MSG = 'Factory name should be singular, not plural.'

        RESTRICT_ON_SEND = %i[factory].freeze

        def on_send(node)
          return unless inside_factory_bot_define?(node)

          factory_name = node.first_argument.value.to_s
          return if factory_name.singularize == factory_name

          add_offense(node.first_argument) do |corrector|
            if node.first_argument.type == :sym
              corrector.replace(node.first_argument.loc.expression, ":#{factory_name.singularize}")
            elsif node.first_argument.type == :str
              if node.first_argument.source.start_with?("'")
                corrector.replace(node.first_argument.loc.expression, "'#{factory_name.singularize}'")
              elsif node.first_argument.source.start_with?('"')
                corrector.replace(node.first_argument.loc.expression, "\"#{factory_name.singularize}\"")
              end
            end
          end
        end

        # Checks if the node is inside a FactoryBot definition block.
        private def inside_factory_bot_define?(node)
          ancestors = node.each_ancestor(:block).to_a
          ancestors.any? { |ancestor| ancestor.method_name == :define && ancestor.receiver&.const_name == 'FactoryBot' }
        end
      end
    end
  end
end
