# frozen_string_literal: true

RSpec.describe Momocop::EnumExtractor do
  describe '#extract' do
    let(:model_content) do
      <<-RUBY
        module AdminPanel
          class User < ApplicationRecord
            enum :role, { admin: 0, user: 1 }
            enum status: { active: 0, inactive: 1 }

            def foo
              :bar
            end
          end
        end
      RUBY
    end

    let(:expected_result) do
      %i[
        role
        status
      ]
    end

    it 'extracts enums from a given string' do
      extractor = described_class.new
      actual = extractor.extract(model_content)
      expect(actual).to match_array(expected_result)
    end

    it 'extracts enums from a given StringIO object' do
      extractor = described_class.new
      actual = extractor.extract(StringIO.new(model_content))
      expect(actual).to match_array(expected_result)
    end

    context 'when enum uses unsupported argument types' do
      let(:model_content) do
        <<-RUBY
          class User < ApplicationRecord
            enum("status", { active: 0, inactive: 1 })
            enum 123
            enum [:foo, :bar]
          end
        RUBY
      end

      it 'ignores enums with unsupported argument types' do
        extractor = described_class.new
        actual = extractor.extract(model_content)
        expect(actual).to be_empty
      end
    end

    context 'when content has no enums' do
      let(:model_content) do
        <<-RUBY
          class User < ApplicationRecord
            def status
              :active
            end
          end
        RUBY
      end

      it 'returns empty array' do
        extractor = described_class.new
        actual = extractor.extract(model_content)
        expect(actual).to be_empty
      end
    end
  end
end
