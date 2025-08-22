# frozen_string_literal: true

module RuboCop
  module Cop
    module Momocop
      module Layout
        # Checks whether comments have a leading space after the
        # `#` denoting the start of the comment. The leading space is not
        # required for some RDoc special syntax, like `#++`, `#--`,
        # `#:nodoc`, `=begin`- and `=end` comments, "shebang" directives,
        # or rackup options, or rbs-inline typing.
        #
        # @example
        #
        #   # bad
        #   #Some comment
        #
        #   # good
        #   # Some comment
        #
        # @example AllowDoxygenCommentStyle: false (default)
        #
        #   # bad
        #
        #   #**
        #   # Some comment
        #   # Another line of comment
        #   #*
        #
        # @example AllowDoxygenCommentStyle: true
        #
        #   # good
        #
        #   #**
        #   # Some comment
        #   # Another line of comment
        #   #*
        #
        # @example AllowGemfileRubyComment: false (default)
        #
        #   # bad
        #
        #   #ruby=2.7.0
        #   #ruby-gemset=myproject
        #
        # @example AllowGemfileRubyComment: true
        #
        #   # good
        #
        #   #ruby=2.7.0
        #   #ruby-gemset=myproject
        #
        class LeadingCommentSpace < RuboCop::Cop::Layout::LeadingCommentSpace
          def on_new_investigation
            processed_source.comments.each do |comment|
              next unless /\A(?!#\+\+|#--)(#+[^#\s=])/.match?(comment.text)
              next if comment.loc.line == 1 && allowed_on_first_line?(comment)
              next if doxygen_comment_style?(comment)
              next if gemfile_ruby_comment?(comment)
              next if rbs_inline_comment_style?(comment)

              add_offense(comment) do |corrector|
                expr = comment.source_range

                corrector.insert_after(hash_mark(expr), ' ')
              end
            end
          end

          def gemfile_ruby_comment?(comment)
            return false unless cop_config['AllowGemfileRubyComment']
            
            comment.text.match?(/\A#ruby(-gemset)?=/)
          end

          def rbs_inline_comment_style?(comment)
            comment.text.start_with?('#:')
          end
        end
      end
    end
  end
end
