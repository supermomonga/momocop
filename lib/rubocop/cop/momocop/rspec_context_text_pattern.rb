# frozen_string_literal: true

module RuboCop
  module Cop
    module Momocop
      class RSpecContextTextPattern < Base
        extend AutoCorrector
        include RangeHelp

        MSG = 'RSpec context text must match pattern: %<pattern>s'

        def_node_matcher :context_block?, <<~PATTERN
          (send nil? :context ...)
        PATTERN

        def on_send(node)
          return unless context_block?(node)

          arg = node.first_argument
          return unless arg&.str_type?

          text = arg.value.to_s
          pattern = cop_config['RequiredPattern']
          return if text.match?(Regexp.new(pattern))

          add_offense(
            node.first_argument.loc.expression,
            message: format(MSG, pattern:)
          )
        end
      end
    end
  end
end
