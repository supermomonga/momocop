# frozen_string_literal: true

require 'parser/current'

module Momocop
  class EnumExtractor
    def extract(source)
      source_string = source.is_a?(StringIO) ? source.string : source
      parse_content(source_string)
    end

    private def parse_content(source)
      buffer = Parser::Source::Buffer.new('(string)')
      buffer.source = source

      parser = Parser::CurrentRuby.new
      ast = parser.parse(buffer)

      extract_enums(ast).sort
    end

    private def extract_enums(node, enums = [])
      if node.type == :send && node.children[1] == :enum
        arg = node.children[2]

        if arg.type == :sym
          # enum :role, { admin: 0, user: 1 }
          enums << arg.children[0]
        elsif arg.type == :hash
          # enum role: { admin: 0, user: 1 }
          enums << arg.children[0].children[0].children[0].to_sym
        end
      elsif node.children.is_a? Array
        node.children.each do |child|
          extract_enums(child, enums) if child.is_a? Parser::AST::Node
        end
      end
      enums
    end
  end
end
