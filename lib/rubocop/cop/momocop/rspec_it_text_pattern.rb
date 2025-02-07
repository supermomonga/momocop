# frozen_string_literal: true

module RuboCop
  module Cop
    module Momocop
      class RSpecItTextPattern < Base
        extend AutoCorrector
        include RangeHelp

        MSG = 'RSpec it block text must match pattern: %<pattern>s'

        def_node_matcher :it_block?, <<~PATTERN
          (send nil? :it ...)
        PATTERN

        def on_send(node)
          return unless it_block?(node)

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
