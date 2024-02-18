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
        enum_name = node.children[2].type == :sym ? node.children[2].children[0] : node.children[2]
        enums << enum_name.to_sym
      elsif node.children.is_a? Array
        node.children.each do |child|
          extract_enums(child, enums) if child.is_a? Parser::AST::Node
        end
      end
      enums
    end
  end
end
