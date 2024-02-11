# frozen_string_literal: true

module RuboCop
  module Cop
    module Momocop
      # Ensures that FactoryBot factories use `ClassName.name` for the class option instead of symbol or string literals.
      #
      # @example
      #   # bad
      #   factory :user, class: :User do
      #   end
      #
      #   factory :admin, class: 'Admin' do
      #   end
      #
      #   factory :moderator, class: Moderator.to_s do
      #   end
      #
      #   # good
      #   factory :user, class: User.name do
      #   end
      #
      #   factory :admin, class: Admin.name do
      #   end
      #
      #   factory :moderator, class: Moderator.name do
      #   end
      class FactoryBotRailsClassName < RuboCop::Cop::Base
        extend AutoCorrector

        MSG = 'Use `ClassName.name` for the class option instead of a symbol, string literal, or `ClassName.to_s`.'

        def_node_matcher :factory_class_option_symbol?, <<~PATTERN
          (send nil? :factory _ (hash <(pair (sym :class) $(sym _)) ...>))
        PATTERN

        def_node_matcher :factory_class_option_string?, <<~PATTERN
          (send nil? :factory _ (hash <(pair (sym :class) $(str _)) ...>))
        PATTERN

        def_node_matcher :factory_class_option_to_s?, <<~PATTERN
          (send nil? :factory _ (hash <(pair (sym :class) $(send _ :to_s)) ...>))
        PATTERN

        def on_send(node)
          factory_class_option_symbol?(node) do |class_option|
            add_offense(class_option) do |corrector|
              corrector.replace(class_option, "#{class_option.value.capitalize}.name")
            end
          end

          factory_class_option_string?(node) do |class_option|
            class_name = class_option.value.delete_prefix("'").delete_suffix("'").capitalize
            add_offense(class_option) do |corrector|
              corrector.replace(class_option, "#{class_name}.name")
            end
          end

          factory_class_option_to_s?(node) do |class_option|
            class_name = class_option.receiver.const_name
            add_offense(class_option) do |corrector|
              corrector.replace(class_option, "#{class_name}.name")
            end
          end
        end
      end
    end
  end
end
