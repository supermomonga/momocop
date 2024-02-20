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

      extract_associations(ast).sort_by { |association| [association[:type], association[:name]] }
    end

    private def extract_associations(node, associations = [])
      association_type = node.children[1]
      options = {}
      if node.type == :send && ASSOCIATION_METHODS.include?(association_type)
        association_name = node.children[2].children[0].to_sym

        # Extract some options
        if association_type == :belongs_to
          option_hash = node.children[3]
          option_hash&.children&.each do |option|
            key_node, value_node = option.children
            # rubocop:disable Lint/BooleanSymbol
            if %i[sym str].include?(value_node.type)
              options[key_node.children[0]] = value_node.children[0]
            elsif value_node.type == :true
              options[key_node.children[0]] = true
            elsif value_node.type == :false
              options[key_node.children[0]] = false
            end
            # rubocop:enable Lint/BooleanSymbol
          end
        end

        associations << { type: association_type, name: association_name, options: }
      elsif node.children.is_a? Array
        node.children.each do |child|
          extract_associations(child, associations) if child.is_a? Parser::AST::Node
        end
      end
      associations
    end
  end
end
