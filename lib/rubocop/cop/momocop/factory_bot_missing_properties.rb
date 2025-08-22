# frozen_string_literal: true

module RuboCop
  module Cop
    module Momocop
      # Ensures that all properties of a Rails model class are defined in a FactoryBot factory,
      # auto-corrects by adding missing properties with sensible defaults based on their types.
      #
      # @example
      #   # bad
      #   FactoryBot.define do
      #     factory :user, class: 'User' do
      #       name { 'John Doe' }
      #     end
      #   end
      #
      #   # Assuming User model has :name, :email (string), :age (integer),
      #   # :role (enum), and :account (association)
      #
      #   # good
      #   FactoryBot.define do
      #     factory :user, class: 'User' do
      #       sequence(:age) { _1 } }
      #       sequence(:email) { "user#{_1}@example.com" }
      #       role { User.roles.keys.sample }
      #       name { 'John Doe' }
      #     end
      #   end
      class FactoryBotMissingProperties < RuboCop::Cop::Base
        extend AutoCorrector
        include RuboCop::Cop::ActiveRecordHelper
        include ::Momocop::Helpers::FactoryBotHelper
        include ::Momocop::Helpers::RailsHelper

        MSG = 'Ensure all properties of the model class are defined in the factory.'

        RESTRICT_ON_SEND = %i[factory].freeze

        def_node_search :sequence_definitions, <<~PATTERN
          (send nil? :sequence ...)
        PATTERN

        def_node_search :property_definitions, <<~PATTERN
          (send nil? $_)
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

          # Exclude defined sequences
          defined_sequences = get_defined_sequence_names(block_node)
          # Exclude defined properties
          defined_properties = get_defined_property_names(block_node)
          # Exclude foreign keys
          model_foreign_keys = get_model_foreign_key_column_names(class_name)
          # All available properties
          model_properties = get_model_property_names(class_name)
          # Calc missing properties
          missing_properties = (
            model_properties -
            (defined_sequences + defined_properties) -
            model_foreign_keys
          )

          # for definition block generation
          model_enum_properties = get_model_enum_property_names(class_name)

          # Add offense for missing properties
          return unless missing_properties.any?

          msg = "Add properties #{missing_properties.map { |p| "`#{p}`" }.join(', ')}."
          # Determine offense range based on whether we have all arguments including 'class' option
          # Find the class option argument (always exists when get_class_name returns non-nil)
          class_option_arg = node.arguments.find { |arg| 
            arg.hash_type? && arg.pairs.any? { |pair| 
              pair.key.sym_type? && pair.key.children.first == :class 
            } 
          }
          
          # Mark from factory to the class option argument
          offense_range = node.loc.selector.join(class_option_arg.loc.expression)
          add_offense(offense_range, message: msg) do |corrector|
            next unless block_node

            # Add newline before closing block if it's a one-liner
            if one_line_block?(block_node)
              indentation = ' ' * node.loc.column
              corrector.insert_before(block_node.loc.end, "\n#{indentation}")
            end

            missing_properties.each do |property|
              definition =
                if model_enum_properties.include?(property)
                  generate_enum_property_definition(class_name, property)
                else
                  generate_property_definition(class_name, property)
                end
              next unless definition

              # TODO: calculate indentation size
              indentation = ' ' * (node.loc.column + 2)
              corrector.insert_after(block_node.loc.begin, "\n#{indentation}#{definition}")
            end
          end
        end

        private def one_line_block?(block_node)
          block_node.loc.begin.line == block_node.loc.end.line
        end

        private def get_defined_sequence_names(block_node)
          body_node = block_node&.children&.last
          return [] unless body_node

          sequences = sequence_definitions(body_node)
          sequence_names = sequences&.map(&:first_argument)&.map(&:value)&.map(&:to_sym)
          return sequence_names
        end

        private def get_defined_property_names(block_node)
          body_node = block_node&.children&.last
          return [] unless body_node

          properties = property_definitions(body_node)
          property_names =
            properties
            &.reject { %i[sequence association].include? _1 }
            &.map(&:to_sym)
          return property_names
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

        private def generate_property_definition(class_name, property)
          table = schema.table_by(name: table_name(class_name))
          column = table.columns.find { |c| c.name.to_sym == property }
          return nil unless column

          case column.type
          when :integer, :float, :decimal
            "sequence(:#{column.name}) { _1 }"
          when :string, :text
            "sequence(:#{column.name}) { \"#{column.name.camelize} #\{_1}\" }"
          when :datetime, :timestamp, :time
            "#{column.name} { Time.zone.now }"
          when :date
            "#{column.name} { Date.today }"
          when :boolean
            "#{column.name} { [true, false].sample }"
          when :json, :jsonb
            "#{column.name} { JSON.parse('{}') }"
          else
            # blob, binary, else
            "#{column.name} { }"
          end
        end

        private def generate_enum_property_definition(class_name, property)
          enum_iteration_method_name = property.to_s.pluralize
          "#{property} { #{class_name}.#{enum_iteration_method_name}.keys.sample }"
        end
      end
    end
  end
end
