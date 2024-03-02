# frozen_string_literal: true

module Momocop
  module Helpers
    module RailsHelper
      include RuboCop::Cop::ActiveRecordHelper

      private def model_file_path(class_name)
        "app/models/#{class_name.underscore}.rb"
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
    end
  end
end
