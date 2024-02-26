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
        include RuboCop::Cop::ActiveRecordHelper
        extend AutoCorrector

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

        private def model_file_path(class_name)
          "app/models/#{class_name.underscore}.rb"
        end

        private def one_line_block?(block_node)
          return false if block_node.nil?

          block_node.loc.begin.line == block_node.loc.end.line
        end

        private def model_file_source(class_name)
          path = model_file_path(class_name)
          return File.read(path) if File.exist?(path)
        end

        private def get_model_association_names(class_name)
          source = model_file_source(class_name)
          return [] unless source

          extractor = ::Momocop::AssociationExtractor.new
          associations = extractor.extract(source)
          belongs_to_associations =
            associations
            .select { _1[:type] == :belongs_to }
            .map { _1[:name].to_s }
          return belongs_to_associations
        end

        private def get_defined_association_names(block_node)
          body_node = block_node&.children&.last
          return [] unless body_node

          associations = association_definitions(body_node)
          association_names = associations&.map(&:first_argument)&.map(&:value)&.map(&:to_s)
          return association_names
        end

        private def generate_association_definition(property)
          "#{property} { association :#{property} }"
        end

        private def inside_factory_bot_define?(node)
          ancestors = node.each_ancestor(:block).to_a
          ancestors.any? { |ancestor| ancestor.method_name == :define && ancestor.receiver&.const_name == 'FactoryBot' }
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
