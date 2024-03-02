# frozen_string_literal: true

module RuboCop
  module Cop
    module Momocop
      # Ensures that each file contains only one top-level FactoryBot factory.
      # Nested factories within a parent factory are allowed.
      #
      # @example
      #   # bad
      #   FactoryBot.define do
      #     factory :user do
      #     end
      #   end
      #
      #   FactoryBot.define do
      #     factory :profile do
      #     end
      #   end
      #
      #   # good
      #   FactoryBot.define do
      #     factory :user do
      #     end
      #   end
      #
      #   # bad
      #   FactoryBot.define do
      #     factory :user do
      #     end
      #   end
      #
      #   FactoryBot.define do
      #     factory :admin_user, class: ‘User' do
      #     end
      #   end
      #
      #   # good
      #   FactoryBot.define do
      #     factory :user do
      #       factory :admin_user do
      #       end
      #     end
      #   end
      class FactoryBotSingleFactoryPerDefine < RuboCop::Cop::Base
        include ::Momocop::Helpers::FactoryBotHelper

        MSG = 'Only one top-level factory is allowed per FactoryBot.define.'

        RESTRICT_ON_SEND = %i[define].freeze

        # Define the investigation method to be called during cop processing.
        def on_send(node)
          return unless factory_bot_define?(node)

          factories = top_level_factories(node)

          return if factories.size <= 1

          # Register an offense for each factory beyond the first one.
          factories[1..].each do |factory|
            add_offense(factory.loc.expression, message: MSG)
          end
        end

        # Returns all top-level factories within a FactoryBot.define block.
        private def top_level_factories(node)
          factory_nodes =
            node
            .block_node
            .body.each_descendant(:send)
            .select { |n| n.method_name == :factory }
          factory_nodes.select { |factory_node|
            base_node = factory_node.block_node || factory_node
            context =
              base_node
              .each_ancestor(:block)
              .map { _1.send_node&.method_name&.to_sym }
              .find { %i[define factory].include? _1 }
            context == :define
          }
        end
      end
    end
  end
end
