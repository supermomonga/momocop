# frozen_string_literal: true

require 'active_support/inflector'

module RuboCop
  module Cop
    module Momocop
      # Ensures that all properties of a Rails model class are defined in a FactoryBot factory,
      # auto-corrects by adding missing properties with sensible defaults based on their types.
      #
      # @example
      #   # Assuming User model has one Account
      #
      #   # bad
      #   FactoryBot.define do
      #     factory :user, class: 'User' do
      #     end
      #   end
      #
      #   # good
      #   FactoryBot.define do
      #     factory :user, class: 'User' do
      #       association(:account)
      #     end
      #   end
      class FactoryBotMissingAssociations < RuboCop::Cop::Base
        extend AutoCorrector
        include RuboCop::Cop::ActiveRecordHelper
        include ::Momocop::Helpers::FactoryBotHelper
        include ::Momocop::Helpers::RailsHelper

        MSG = 'Ensure all associations of the model class are defined in the factory.'

        RESTRICT_ON_SEND = %i[factory].freeze

        def_node_search :association_definitions, <<~PATTERN
          (send nil? :association ...)
        PATTERN

        def on_send(node)
          return unless inside_factory_bot_define?(node)

          class_name = get_class_name(node)
          return unless class_name

          block_node = node.block_node

          # Add block if it's missing
          unless block_node
            add_offense(node, message: MSG) do |corrector|
              indentation = ' ' * node.loc.column
              corrector.replace(node.source_range, "#{node.source} do\n#{indentation}end")
            end
          end

          # Check missing associations
          defined_associations = get_defined_association_names(block_node)
          model_associations = get_model_association_names(class_name)
          missing_associations = (model_associations - defined_associations).sort

          # Add offense for missing associations
          return unless missing_associations.any?

          add_offense(node, message: MSG) do |corrector|
            # Add newline before closing block if it's a one-liner
            if one_line_block?(block_node)
              indentation = ' ' * node.loc.column
              corrector.insert_before(block_node.loc.end, "\n#{indentation}")
            end

            missing_associations.each do |property|
              definition = generate_association_definition(property)
              break unless definition

              # TODO: calculate indentation size
              indentation = ' ' * (node.loc.column + 2)

              # use send node if blockless
              corrector.insert_after(block_node.loc.begin, "\n#{indentation}#{definition}")
            end
          end
        end

        private def one_line_block?(block_node)
          return false if block_node.nil?

          block_node.loc.begin.line == block_node.loc.end.line
        end

        private def get_defined_association_names(block_node)
          body_node = block_node&.children&.last
          return [] unless body_node

          associations = association_definitions(body_node)
          association_names = associations&.map { |node| get_association_name(node) }
          return association_names
        end

        private def get_association_name(node)
          # Explicit definition
          return node.arguments.first.value.to_s if inside_factory_bot_factory?(node)

          # Inline definition
          context = node.each_ancestor(:block).first
          send_node = context.block_type? ? context.send_node : context
          return send_node.method_name.to_s
        end

        private def generate_association_definition(property)
          "#{property} { association :#{property} }"
        end

        private def get_class_name(node)
          options_hash = node.arguments[1]
          return nil unless options_hash&.type == :hash

          class_option = options_hash.pairs.find { |pair| pair.key.value == :class }
          return nil unless class_option

          value = class_option.value
          return nil unless value.str_type? || value.sym_type?

          return value.value.to_s
        end
      end
    end
  end
end
