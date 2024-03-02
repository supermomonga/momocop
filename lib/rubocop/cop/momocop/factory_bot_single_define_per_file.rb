# frozen_string_literal: true

module RuboCop
  module Cop
    module Momocop
      # This cop checks for multiple `FactoryBot.define` blocks in a single file.
      # It's recommended to have only one `FactoryBot.define` block per file to keep
      # factory definitions clear and maintainable.
      #
      # @example
      #   # bad
      #   FactoryBot.define do
      #     factory :user do
      #     end
      #   end
      #
      #   FactoryBot.define do
      #     factory :admin do
      #     end
      #   end
      #
      #   # good
      #   FactoryBot.define do
      #     factory :user do
      #     end
      #     factory :admin do
      #     end
      #   end
      class FactoryBotSingleDefinePerFile < RuboCop::Cop::Base
        include ::Momocop::Helpers::FactoryBotHelper

        MSG = 'Only one `FactoryBot.define` block is allowed per file.'

        def on_new_investigation
          factory_bot_define_blocks =
            processed_source
            .ast
            .descendants
            .select { |node|
              factory_bot_define?(node)
            }

          return if factory_bot_define_blocks.size <= 1

          factory_bot_define_blocks[1..].each do |factory_bot_define_block|
            add_offense(factory_bot_define_block, message: MSG)
          end
        end
      end
    end
  end
end
