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
      class FactoryBotRailsClassOptionExistence < RuboCop::Cop::Base
        extend AutoCorrector

        MSG = 'Specified class does not exist. Please make sure that the class exists.'

        def_node_matcher :factory_class_option_symbol?, <<~PATTERN
          (send nil? :factory _ (hash <(pair (sym :class) $(sym _)) ...>))
        PATTERN

        def_node_matcher :factory_class_option_string?, <<~PATTERN
          (send nil? :factory _ (hash <(pair (sym :class) $(str _)) ...>))
        PATTERN

        def on_send(node)
          class_node = factory_class_option_symbol?(node) || factory_class_option_string?(node)

          return unless class_node

          class_name = class_node.value.to_s
          puts class_name

          return if class_exists?(class_name)

          add_offense(class_node)
        end

        private def model_file_path(class_name)
          "app/models/#{class_name.underscore}.rb"
        end

        private def class_exists?(class_name)
          File.exist?(model_file_path(class_name))
        end
      end
    end
  end
end
