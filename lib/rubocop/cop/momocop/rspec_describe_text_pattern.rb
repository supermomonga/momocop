# frozen_string_literal: true

module RuboCop
  module Cop
    module Momocop
      class RSpecDescribeTextPattern < Base
        extend AutoCorrector
        include RangeHelp

        MSG = 'RSpec describe のテキストは「%<pattern>s」にマッチする必要があります'

        def_node_matcher :describe_block?, <<~PATTERN
          (send nil? :describe ...)
        PATTERN

        def on_send(node)
          return unless describe_block?(node)

          text_node = node.arguments.first
          return unless text_node&.str_type?

          text = text_node.value.to_s
          return if text.match?(allowed_pattern)

          add_offense(
            text_node,
            message: format(MSG, pattern: cop_config['AllowedPattern'])
          )
        end

        private

        def allowed_pattern
          @allowed_pattern ||= Regexp.new(cop_config['AllowedPattern'])
        end
      end
    end
  end
end
