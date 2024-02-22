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
        include RuboCop::Cop::ActiveRecordHelper
        extend AutoCorrector

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
          ).sort

          # for definition block generation
          model_enum_properties = get_model_enum_property_names(class_name)

          # Add offense for missing properties
          return unless missing_properties.any?

          add_offense(node, message: MSG) do |corrector|
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

        private def model_file_path(class_name)
          "app/models/#{class_name.underscore}.rb"
        end

        private def one_line_block?(block_node)
          block_node.loc.begin.line == block_node.loc.end.line
        end

        private def model_file_source(class_name)
          path = model_file_path(class_name)
          return File.read(path) if File.exist?(path)
        end

        private def get_model_enum_property_names(class_name)
          source = model_file_source(class_name)
          return [] unless source

          extractor = ::Momocop::EnumExtractor.new
          enums = extractor.extract(source)
          return enums.map(&:to_sym)
        end

        private def get_model_foreign_key_column_names(class_name)
          source = model_file_source(class_name)
          return [] unless source

          extractor = ::Momocop::AssociationExtractor.new
          associations = extractor.extract(source)
          foreign_key_names =
            associations
            .select { _1[:type] == :belongs_to }
            .map { |association|
              options = association[:options]
              options[:foreign_key] || "#{association[:name]}_id"
            }
            .compact
          return foreign_key_names.map(&:to_sym)
        end

        RESTRICTED_COLUMNS = %w[created_at updated_at].freeze

        private def get_model_property_names(class_name)
          table = schema.table_by(name: table_name(class_name))
          return [] unless table

          column_names = table.columns.reject { _1.type == :references }.map(&:name) - RESTRICTED_COLUMNS
          return column_names.map(&:to_sym)
        end

        # e.g.)
        # 'User' -> ['users']
        # 'Admin::User' -> ['admin_users', 'users']
        private def table_name(class_name)
          # TODO: parse model class file and try to get table_name_prefix and table_name_suffix
          class_name.tableize.gsub('/', '_')
        end

        # e.g.)
        # 'User' -> ['users']
        # 'Admin::User' -> ['admin_users', 'users']
        private def foreign_key_name(class_name)
          # TODO: parse model class file and try to get table_name_prefix and table_name_suffix
          "#{class_name.underscore.gsub('/', '_')}_id"
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
