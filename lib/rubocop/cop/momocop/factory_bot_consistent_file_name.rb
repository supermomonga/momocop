# frozen_string_literal: true

module RuboCop
  module Cop
    module Momocop
      # Ensures that FactoryBot factory names match their filenames.
      #
      # @example
      #   # bad
      #   # in a file named user.rb
      #   FactoryBot.define do
      #     factory :admin_user do
      #     end
      #   end
      #
      #   # good
      #   # in a file named admin_user.rb
      #   FactoryBot.define do
      #     factory :admin_user do
      #     end
      #   end
      class FactoryBotConsistentFileName < RuboCop::Cop::Base
        include RangeHelp
        include ::Momocop::Helpers::FactoryBotHelper

        MSG = 'Factory name should match the file name.'

        RESTRICT_ON_SEND = %i[factory].freeze

        def_node_matcher :factory_bot_definition, <<~PATTERN
          (send nil? :factory ({sym str} $_) ...)
        PATTERN

        def on_send(node)
          factory_name = factory_bot_definition(node)
          return unless factory_name

          return unless inside_factory_bot_define?(node)

          expected_file_name = "#{factory_name}.rb"
          actual_file_name = File.basename(processed_source.file_path)
          return unless actual_file_name != expected_file_name

          add_offense(node.source_range, message: MSG)
        end
      end
    end
  end
end
