# frozen_string_literal: true

module RuboCop
  module Cop
    module Momocop
      # Ensures that FactoryBot factories explicitly specify a class.
      #
      # @example
      #   # bad
      #   factory :user do
      #   end
      #
      #   # good
      #   factory :user, class: 'User' do
      #   end
      class FactoryBotMissingClassOption < RuboCop::Cop::Base
        extend AutoCorrector

        MSG = 'Specify a class option explicitly in FactoryBot factory.'

        RESTRICT_ON_SEND = %i[factory].freeze

        def on_send(node)
          return unless inside_factory_bot_define?(node)

          # `factory`メソッドの呼び出しで、ハッシュ引数に`:class`キーが含まれているかを調べる
          class_option_specified = node.arguments.any? { |arg|
            arg.hash_type? && arg.pairs.any? { |pair| pair.key.sym_type? && pair.key.children.first == :class }
          }
          return if class_option_specified

          add_offense(node.loc.selector) do |corrector|
            # Assuming the factory name matches the class name.
            # You may need a more sophisticated approach for different naming conventions.
            require 'active_support/core_ext/string/inflections'
            class_name = node.first_argument.value.to_s.camelize
            corrector.insert_after(node.first_argument.loc.expression, ", class: '#{class_name}'")
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
