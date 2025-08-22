# frozen_string_literal: true

RSpec.describe Momocop::AssociationExtractor do
  describe '#extract' do
    let(:model_content) do
      <<-RUBY
        module AdminPanel
          class User < ApplicationRecord
            has_many :articles, class: 'Article'
            belongs_to :role, dependent: :destroy, class: 'Role', optional: true
            belongs_to :group, dependent: :destroy, foreign_key: :user_group_id
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
        { type: :belongs_to, name: :group, options: { dependent: :destroy, foreign_key: :user_group_id } },
        { type: :belongs_to, name: :role, options: { dependent: :destroy, class: 'Role', optional: true } },
        { type: :has_many, name: :articles, options: {} },
        { type: :has_one, name: :profile, options: {} }
      ]
    end

    it 'extracts associations from a given string' do
      extractor = described_class.new
      actual = extractor.extract(model_content)
      expect(actual).to eq(expected_result)
    end

    it 'extracts associations from a given StringIO object' do
      extractor = described_class.new
      actual = extractor.extract(StringIO.new(model_content))
      expect(actual).to eq(expected_result)
    end

    context 'with false option values' do
      let(:model_content) do
        <<-RUBY
          class User < ApplicationRecord
            belongs_to :account, optional: false
            belongs_to :team, dependent: false
          end
        RUBY
      end

      it 'correctly handles false option values' do
        extractor = described_class.new
        actual = extractor.extract(model_content)
        expected = [
          { type: :belongs_to, name: :account, options: { optional: false } },
          { type: :belongs_to, name: :team, options: { dependent: false } }
        ]
        expect(actual).to eq(expected)
      end
    end

    context 'when node has no children array' do
      let(:model_content) do
        <<-RUBY
          # Just a comment
        RUBY
      end

      it 'returns empty array' do
        extractor = described_class.new
        actual = extractor.extract(model_content)
        expect(actual).to eq([])
      end
    end
  end
end
