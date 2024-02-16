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
      class FactoryBotRailsClassOptionSpecified < RuboCop::Cop::Base
        extend AutoCorrector

        MSG = 'Specify a class option explicitly in FactoryBot factory.'

        def_node_matcher :factory_call?, <<~PATTERN
          (send nil? :factory ...)
        PATTERN

        def on_send(node)
          return unless factory_call?(node)

          # `factory`メソッドの呼び出しで、ハッシュ引数に`:class`キーが含まれているかを調べる
          class_option_specified = node.arguments.any? do |arg|
            arg.hash_type? && arg.pairs.any? { |pair| pair.key.sym_type? && pair.key.children.first == :class }
          end
          return if class_option_specified

          add_offense(node.loc.selector) do |corrector|
            # Assuming the factory name matches the class name.
            # You may need a more sophisticated approach for different naming conventions.
            require 'active_support/core_ext/string/inflections'
            class_name = node.first_argument.value.to_s.camelize
            corrector.insert_after(node.first_argument.loc.expression, ", class: '#{class_name}'")
          end
        end
      end
    end
  end
end
