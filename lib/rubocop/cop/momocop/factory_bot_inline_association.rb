# frozen_string_literal: true

module RuboCop
  module Cop
    module Momocop
      # Enforces inline association definitions in FactoryBot factories.
      #
      # @example
      #   # bad
      #   factory :blog_post do
      #     association(:user, factory: :foo)
      #     association(:admin, factory: [:foo, :trait])
      #   end
      #
      #   # good
      #   factory :blog_post do
      #     user { association :foo }
      #     admin { association :foo, :trait }
      #   end
      class FactoryBotInlineAssociation < RuboCop::Cop::Base
        extend AutoCorrector
        include ::Momocop::Helpers::FactoryBotHelper

        MSG = 'Use inline association definition instead of separate `association` method call.'

        RESTRICT_ON_SEND = %i[association].freeze

        def_node_matcher :association_call?, <<-PATTERN
          (send nil? :association (sym _))
        PATTERN

        def on_send(node)
          return unless inside_factory_bot_define?(node)
          return unless inside_factory_bot_factory?(node)

          add_offense(node.loc.selector, message: MSG) do |corrector|
            association_name = node.arguments.first.value
            options = node.arguments.at(1)

            convert_options(options) in {
              factory_option:, rest_options:
            }
            factory = factory_option || ":#{association_name}"
            replacement =
              if rest_options.empty?
                "#{association_name} { association #{factory} }"
              else
                rest_options_source = rest_options.map(&:source).join(', ')
                "#{association_name} { association #{factory}, #{rest_options_source} }"
              end
            corrector.replace(node, replacement)
          end
        end

        # `association :foo, factory: :bar, baz: 1 ...` => `foo { association :bar, baz: 1 ...}`
        private def convert_options(options)
          factory_option =
            options
            &.pairs
            &.find { |pair| pair.key.value == :factory }
            &.value
            &.then { _1.array_type? ? _1.values.map(&:source).join(', ') : _1.source }
          rest_options = options&.pairs&.reject { |pair| pair.key.value == :factory } || []

          return {
            factory_option:,
            rest_options:
          }
        end
      end
    end
  end
end
