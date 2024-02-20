# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Momocop::FactoryBotMissingAssociations, :config do
  let(:config) { RuboCop::Config.new }

  before do
    # mock model file source
    mock_model_source = <<-RUBY
      class User < ApplicationRecord
        belongs_to :account
        belongs_to :profile, optional: true
        has_one :role
        has_many :articles
      end
    RUBY
    allow_any_instance_of(described_class).to receive(:model_file_source).and_return(mock_model_source)
  end

  context 'when all associations are defined in the factory' do
    it 'registers no offense' do
      expect_no_offenses(<<~RUBY)
        FactoryBot.define do
          factory :user, class: 'User' do
            association(:account)
            association(:profile)
          end
        end
      RUBY
    end
  end

  context 'when an association is missing in the factory' do
    it 'registers offense and corrects' do
      expect_offense(<<~RUBY)
        FactoryBot.define do
          factory(:user, class: 'User') do
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Momocop/FactoryBotMissingAssociations: Ensure all associations of the model class are defined in the factory.
            association(:account)
          end
        end
      RUBY

      expect_correction(<<~RUBY)
        FactoryBot.define do
          factory(:user, class: 'User') do
            association(:profile)
            association(:account)
          end
        end
      RUBY
    end
  end

  context 'when block is one liner' do
    it 'insert newline and indent' do
      expect_offense(<<~RUBY)
        FactoryBot.define do
          factory(:user, class: 'User') {}
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Momocop/FactoryBotMissingAssociations: Ensure all associations of the model class are defined in the factory.
        end
      RUBY

      expect_correction(<<~RUBY)
        FactoryBot.define do
          factory(:user, class: 'User') {
            association(:account)
            association(:profile)
          }
        end
      RUBY
    end
  end

  context 'when block is missing' do
    it 'creates block' do
      expect_offense(<<~RUBY)
        FactoryBot.define do
          factory :user, class: 'User'
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Momocop/FactoryBotMissingAssociations: Ensure all associations of the model class are defined in the factory.
        end
      RUBY

      expect_correction(<<~RUBY)
        FactoryBot.define do
          factory :user, class: 'User' do
            association(:account)
            association(:profile)
          end
        end
      RUBY
    end
  end

  describe '#model_file_path' do
    it 'returns correct file path' do
      cop = RuboCop::Cop::Momocop::FactoryBotMissingAssociations.new
      actual = cop.send(:model_file_path, 'User')
      expected = 'app/models/user.rb'

      expect(actual).to eq(expected)
    end
  end
end
