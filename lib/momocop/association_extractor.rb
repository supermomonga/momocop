# frozen_string_literal: true

require 'parser/current'

module Momocop
  class AssociationExtractor
    ASSOCIATION_METHODS = %i[has_many belongs_to has_one].freeze

    def extract(source)
      source_string = source.is_a?(StringIO) ? source.string : source
      parse_content(source_string)
    end

    private def parse_content(source)
      buffer = Parser::Source::Buffer.new('(string)')
      buffer.source = source

      parser = Parser::CurrentRuby.new
      ast = parser.parse(buffer)

      extract_associations(ast)
    end

    private def extract_associations(node, associations = [])
      if node.type == :send && ASSOCIATION_METHODS.include?(node.children[1])
        association_name = node.children[2].type == :sym ? node.children[2].children[0] : node.children[2]
        associations << { type: node.children[1], name: association_name }
      elsif node.children.is_a? Array
        node.children.each do |child|
          extract_associations(child, associations) if child.is_a? Parser::AST::Node
        end
      end
      associations
    end
  end
end
