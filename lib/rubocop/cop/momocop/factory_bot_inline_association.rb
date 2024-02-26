# frozen_string_literal: true

module RuboCop
  module Cop
    module Momocop
      # Enforces inline association definitions in FactoryBot factories.
      #
      # @example
      #   # bad
      #   factory :blog_post do
      #     association(:user)
      #   end
      #
      #   # good
      #   factory :blog_post do
      #     user { association :user }
      #   end
      class FactoryBotInlineAssociation < RuboCop::Cop::Base
        extend AutoCorrector

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
            options = node.arguments.drop(1).map(&:source).join(', ')

            replacement =
              if options.empty?
                "#{association_name} { association :#{association_name} }"
              else
                "#{association_name} { association :#{association_name}, #{options} }"
              end
            corrector.replace(node, replacement)
          end
        end

        private def inside_factory_bot_factory?(node)
          context = node.each_ancestor(:block).first
          send_node = context.block_type? ? context.send_node : context

          return send_node.method_name == :factory
        end

        private def inside_factory_bot_define?(node)
          ancestors = node.each_ancestor(:block).to_a
          ancestors.any? { |ancestor| ancestor.method_name == :define && ancestor.receiver&.const_name == 'FactoryBot' }
        end
      end
    end
  end
end
