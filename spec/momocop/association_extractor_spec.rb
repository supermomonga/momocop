# frozen_string_literal: true

RSpec.describe Momocop::AssociationExtractor do
  describe '#extract' do
    let(:model_content) do
      <<-RUBY
        module AdminPanel
          class User < ApplicationRecord
            has_many :articles, class: 'Article'
            belongs_to :role, dependent: :destroy, class: 'Role'
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
        { type: :belongs_to, name: :role, options: { dependent: :destroy, class: 'Role' } },
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
  end
end
