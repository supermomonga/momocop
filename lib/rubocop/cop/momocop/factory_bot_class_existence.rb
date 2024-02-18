# frozen_string_literal: true

module RuboCop
  module Cop
    module Momocop
      # Ensures that FactoryBot factories has a valid class option.
      #
      # @example
      #   # bad (if 'app/models/user.rb' does not exist)
      #   factory :user, class: 'User' do
      #   end
      #
      #   # good (if 'app/models/admin.rb' exists)
      #   factory :user, class: 'Admin' do
      #   end
      class FactoryBotClassExistence < RuboCop::Cop::Base
        extend AutoCorrector

        MSG = 'Specified class does not exist. Please make sure that the class exists.'

        RESTRICT_ON_SEND = %i[factory].freeze

        def_node_matcher :factory_class_option_symbol?, <<~PATTERN
          (send nil? :factory _ (hash <(pair (sym :class) $(sym _)) ...>))
        PATTERN

        def_node_matcher :factory_class_option_string?, <<~PATTERN
          (send nil? :factory _ (hash <(pair (sym :class) $(str _)) ...>))
        PATTERN

        def on_send(node)
          return unless inside_factory_bot_define?(node)

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

        private def inside_factory_bot_define?(node)
          ancestors = node.each_ancestor(:block).to_a
          ancestors.any? { |ancestor| ancestor.method_name == :define && ancestor.receiver&.const_name == 'FactoryBot' }
        end
      end
    end
  end
end
