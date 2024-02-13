# frozen_string_literal: true

RSpec.describe Momocop::AssociationExtractor do
  describe '#extract' do
    let(:model_content) do
      <<-RUBY
        module AdminPanel
          class User < ApplicationRecord
            has_many :articles, class: 'Article'
            belongs_to :role, dependent: :destroy
            has_one :profile

            def foo
              :bar
            end
          end
        end
      RUBY
    end

    let(:expected_result) do
      [
        { type: :has_many, name: :articles },
        { type: :belongs_to, name: :role },
        { type: :has_one, name: :profile }
      ]
    end

    it 'extracts associations from a given string' do
      extractor = described_class.new
      actual = extractor.extract(model_content)
      expect(actual).to match_array(expected_result)
    end

    it 'extracts associations from a given StringIO object' do
      extractor = described_class.new
      actual = extractor.extract(StringIO.new(model_content))
      expect(actual).to match_array(expected_result)
    end
  end
end
