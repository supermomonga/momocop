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
          return if text.match?(required_pattern)

          source_range = text_node.source_range
          add_offense(
            Parser::Source::Range.new(
              source_range.source_buffer,
              source_range.begin_pos + 1,
              source_range.end_pos - 1
            ),
            message: format(MSG, pattern: cop_config['RequiredPattern'])
          )
        end

        private

        def required_pattern
          @required_pattern ||= Regexp.new(cop_config['RequiredPattern'])
        end
      end
    end
  end
end
